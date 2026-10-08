import 'dart:convert';
import 'dart:io';

import 'package:synchronized/synchronized.dart';

/// Thrown when a git invocation made by [WorktreeManager] fails. Any
/// credentials in a URL git echoed are redacted.
class WorktreeException implements Exception {
  WorktreeException(String message, {required String stderr})
    : message = redactCredentials(message),
      stderr = redactCredentials(stderr);

  final String message;
  final String stderr;

  @override
  String toString() => '$message: $stderr';
}

/// [text] with the userinfo of any URL in it (`https://x:TOKEN@host`)
/// replaced by `***`.
String redactCredentials(String text) =>
    text.replaceAll(RegExp(r'://[^/\s@]+@'), '://***@');

/// A remote URL as the server hands it out — possibly with an access token
/// as its userinfo — split into a [url] without credentials and the
/// `Authorization` header git sends instead. The header reaches git through
/// its environment, so the token is never written to `repo.git/config`, a
/// `FETCH_HEAD`, or a command line `ps` shows.
class GitRemote {
  GitRemote._(this.url, this.authHeader);

  factory GitRemote.parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.userInfo.isEmpty) return GitRemote._(url, null);
    final credentials = Uri.decodeComponent(uri.userInfo);
    return GitRemote._(
      uri.replace(userInfo: '').toString(),
      'Authorization: Basic ${base64Encode(utf8.encode(credentials))}',
    );
  }

  final String url;
  final String? authHeader;
}

/// Manages git-worktree-based execution isolation per project
/// (docs/ARCHITECTURE.md): one bare clone per project on disk, and one worktree
/// + branch per
/// task, so concurrent tasks on the same project never share a working
/// directory.
///
/// Disk layout under [workspaceRoot]:
/// ```
/// <workspaceRoot>/<projectId>/repo.git/            (bare clone)
/// <workspaceRoot>/<projectId>/worktrees/<taskId>/   (per-task worktree)
/// ```
class WorktreeManager {
  WorktreeManager({required this.workspaceRoot});

  final String workspaceRoot;

  final Map<String, Lock> _projectLocks = {};

  Lock _lockFor(String projectId) =>
      _projectLocks.putIfAbsent(projectId, Lock.new);

  String _projectDir(String projectId) => '$workspaceRoot/$projectId';

  String _bareRepoDir(String projectId) => '${_projectDir(projectId)}/repo.git';

  String _worktreeDir(String projectId, String taskId) =>
      '${_projectDir(projectId)}/worktrees/$taskId';

  /// Where the remote's default branch is fetched to — new task branches
  /// start from it. A dedicated ref rather than `refs/heads/<default>`:
  /// fetching into a branch a worktree may have checked out is refused.
  static const baseRef = 'refs/roundtable/base';

  /// Runs git with config that a run can't override: an agent can write to
  /// its worktree (and, natively, anywhere), so hooks and `core.fsmonitor`
  /// — commands git would run on the host — are switched off, and nothing
  /// prompts for a password. [remote]'s credentials go in as an extra
  /// header. Returns stdout; throws a [WorktreeException] naming [what].
  Future<String> _git(
    List<String> args, {
    required String what,
    required String cwd,
    GitRemote? remote,
  }) async {
    final config = {
      'core.hooksPath': '/dev/null',
      'core.fsmonitor': 'false',
      'http.extraHeader': ?remote?.authHeader,
    };
    final result = await Process.run(
      'git',
      args,
      workingDirectory: cwd,
      environment: {
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_CONFIG_COUNT': '${config.length}',
        for (final (i, MapEntry(:key, :value)) in config.entries.indexed) ...{
          'GIT_CONFIG_KEY_$i': key,
          'GIT_CONFIG_VALUE_$i': value,
        },
      },
    );
    if (result.exitCode != 0) {
      throw WorktreeException('$what failed', stderr: '${result.stderr}');
    }
    return '${result.stdout}'.trim();
  }

  /// `--git-dir`/`--work-tree` for git commands on [taskId]'s worktree. The
  /// worktree's own `.git` file is never followed: whoever ran in the
  /// worktree could point it at a repository with its own config. The
  /// admin directory is found from `repo.git`, which a run can't write.
  List<String> _worktreeArgs(String projectId, String taskId) {
    final worktreeDir = _worktreeDir(projectId, taskId);
    final admin = Directory('${_bareRepoDir(projectId)}/worktrees');
    final gitDir = admin.existsSync()
        ? admin.listSync().whereType<Directory>().where((d) {
            final file = File('${d.path}/gitdir');
            return file.existsSync() &&
                file.readAsStringSync().trim() == '$worktreeDir/.git';
          }).firstOrNull
        : null;
    if (gitDir == null) {
      throw WorktreeException(
        'no git metadata for task $taskId on project $projectId',
        stderr: '',
      );
    }
    return ['--git-dir=${gitDir.path}', '--work-tree=$worktreeDir'];
  }

  /// Ensures a bare clone for [projectId] exists, cloning from [cloneUrl] if
  /// it doesn't, then fetches the remote's current default branch into
  /// [baseRef]. Without the fetch every task would branch from the commit
  /// the project had when it was first cloned on this machine. Idempotent —
  /// safe to call every time a task for this project starts.
  ///
  /// The clone's `origin` is (re)set to [cloneUrl] without credentials:
  /// clones made before [GitRemote] kept the token there.
  Future<void> ensureProjectCloned({
    required String projectId,
    required String cloneUrl,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    final remote = GitRemote.parse(cloneUrl);
    return _lockFor(projectId).synchronized(() async {
      final repoDir = _bareRepoDir(projectId);
      if (!Directory(repoDir).existsSync()) {
        await Directory(_projectDir(projectId)).create(recursive: true);
        await _git(
          ['clone', '--bare', remote.url, repoDir],
          what: 'git clone --bare for project $projectId',
          cwd: _projectDir(projectId),
          remote: remote,
        );
      }
      await _git(
        ['config', 'remote.origin.url', remote.url],
        what: 'resetting the origin of project $projectId',
        cwd: repoDir,
      );
      await _git(
        ['fetch', remote.url, '+HEAD:$baseRef'],
        what: 'git fetch of the default branch for project $projectId',
        cwd: repoDir,
        remote: remote,
      );
    });
  }

  /// Creates an isolated worktree + branch (`task-<taskId>`), starting from
  /// the remote's latest default branch, for [taskId]
  /// under project [projectId], or returns the existing one if it already
  /// exists on disk (a feedback iteration reuses the same worktree —
  /// docs/ARCHITECTURE.md). Serialized per-project. Returns the absolute
  /// worktree path.
  Future<String> createWorktree({
    required String projectId,
    required String taskId,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(taskId, name: 'taskId');
    return _lockFor(projectId).synchronized(() async {
      final worktreeDir = _worktreeDir(projectId, taskId);
      if (Directory(worktreeDir).existsSync()) return worktreeDir;

      await Directory(
        '${_projectDir(projectId)}/worktrees',
      ).create(recursive: true);
      await _git(
        // Branch from the freshly fetched default branch (see
        // [ensureProjectCloned]), not the bare clone's stale HEAD.
        ['worktree', 'add', worktreeDir, '-b', 'task-$taskId', baseRef],
        what: 'git worktree add for task $taskId on project $projectId',
        cwd: _bareRepoDir(projectId),
      );
      return worktreeDir;
    });
  }

  /// Discards uncommitted changes in the worktree for [taskId] (used when
  /// cancelling a run mid-task — docs/FLOWS.md §4). No-op if the worktree
  /// doesn't exist.
  Future<void> resetWorktree({
    required String projectId,
    required String taskId,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(taskId, name: 'taskId');
    return _lockFor(projectId).synchronized(() async {
      final worktreeDir = _worktreeDir(projectId, taskId);
      if (!Directory(worktreeDir).existsSync()) return;
      final worktree = _worktreeArgs(projectId, taskId);
      final label = 'for task $taskId on project $projectId';
      await _git(
        [...worktree, 'reset', '--hard'],
        what: 'git reset --hard $label',
        cwd: worktreeDir,
      );
      await _git(
        [...worktree, 'clean', '-fd'],
        what: 'git clean -fd $label',
        cwd: worktreeDir,
      );
    });
  }

  /// Removes the worktree for a finished task and its local branch.
  /// Idempotent — no-op if the worktree is already gone. Serialized
  /// per-project.
  Future<void> removeWorktree({
    required String projectId,
    required String taskId,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(taskId, name: 'taskId');
    return _lockFor(projectId).synchronized(() async {
      final worktreeDir = _worktreeDir(projectId, taskId);
      if (!Directory(worktreeDir).existsSync()) return;
      final repo = _bareRepoDir(projectId);
      final label = 'for task $taskId on project $projectId';
      await _git(
        ['worktree', 'remove', '--force', worktreeDir],
        what: 'git worktree remove $label',
        cwd: repo,
      );
      await _git(
        ['worktree', 'prune'],
        what: 'git worktree prune for project $projectId',
        cwd: repo,
      );
      await _git(
        ['branch', '-D', 'task-$taskId'],
        what: 'git branch -D $label',
        cwd: repo,
      );
    });
  }

  /// Commits any pending changes in the task's worktree and pushes the
  /// resulting branch to [pushUrl] (docs/FLOWS.md §4). Returns `false`
  /// without committing or pushing if the worktree has no changes — nothing
  /// for the agent to have done. [pushUrl]'s credentials go through
  /// [GitRemote], never into git config or a command line.
  Future<bool> commitAndPush({
    required String projectId,
    required String taskId,
    required String commitMessage,
    required String pushUrl,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(taskId, name: 'taskId');
    final remote = GitRemote.parse(pushUrl);
    return _lockFor(projectId).synchronized(() async {
      final worktreeDir = _worktreeDir(projectId, taskId);
      if (!Directory(worktreeDir).existsSync()) {
        throw WorktreeException(
          'no worktree for task $taskId on project $projectId',
          stderr: '',
        );
      }
      final worktree = _worktreeArgs(projectId, taskId);
      final label = 'for task $taskId on project $projectId';

      await _git(
        [...worktree, 'add', '-A'],
        what: 'git add $label',
        cwd: worktreeDir,
      );
      final status = await _git(
        [...worktree, 'status', '--porcelain'],
        what: 'git status $label',
        cwd: worktreeDir,
      );
      if (status.isEmpty) return false;

      await _git(
        [
          ...worktree,
          '-c',
          'user.name=Roundtable Agent',
          '-c',
          'user.email=agent@roundtable.local',
          'commit',
          '-m',
          commitMessage,
        ],
        what: 'git commit $label',
        cwd: worktreeDir,
      );
      await _git(
        [...worktree, 'push', remote.url, 'HEAD:refs/heads/task-$taskId'],
        what: 'git push $label',
        cwd: worktreeDir,
        remote: remote,
      );
      return true;
    });
  }

  String _reviewDir(String projectId, String reviewId) =>
      '${_projectDir(projectId)}/reviews/$reviewId';

  /// Fetches [branch] and the remote's default branch from [fetchUrl] and
  /// checks the branch out, detached, into a worktree for [reviewId] — a
  /// reviewer may run on a machine that never had the task's worktree, and
  /// detaching means it never touches the `task-<id>` branch. Returns the
  /// worktree path and the merge base to diff against.
  Future<({String path, String baseSha})> createReviewWorktree({
    required String projectId,
    required String reviewId,
    required String branch,
    required String fetchUrl,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(reviewId, name: 'reviewId');
    final remote = GitRemote.parse(fetchUrl);
    return _lockFor(projectId).synchronized(() async {
      final repo = _bareRepoDir(projectId);
      final headRef = 'refs/roundtable-reviews/$reviewId/head';
      final baseRef = 'refs/roundtable-reviews/$reviewId/base';
      final label = 'for review $reviewId on project $projectId';

      await _git(
        ['fetch', remote.url, '+refs/heads/$branch:$headRef', '+HEAD:$baseRef'],
        what: 'git fetch $label',
        cwd: repo,
        remote: remote,
      );
      final dir = _reviewDir(projectId, reviewId);
      if (Directory(dir).existsSync()) {
        await _git(
          ['worktree', 'remove', '--force', dir],
          what: 'git worktree remove $label',
          cwd: repo,
        );
      }
      await Directory(
        '${_projectDir(projectId)}/reviews',
      ).create(recursive: true);
      await _git(
        ['worktree', 'add', '--detach', dir, headRef],
        what: 'git worktree add $label',
        cwd: repo,
      );
      final baseSha = await _git(
        ['merge-base', baseRef, headRef],
        what: 'git merge-base $label',
        cwd: repo,
      );
      return (path: dir, baseSha: baseSha);
    });
  }

  /// Removes [reviewId]'s worktree and refs. Idempotent: best effort, a
  /// failure is only reported through [onError].
  Future<void> removeReviewWorktree({
    required String projectId,
    required String reviewId,
    void Function(Object error)? onError,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(reviewId, name: 'reviewId');
    return _lockFor(projectId).synchronized(() async {
      final repo = _bareRepoDir(projectId);
      final dir = _reviewDir(projectId, reviewId);
      Future<void> bestEffort(List<String> args) async {
        try {
          await _git(
            args,
            what: 'git ${args.first} for review $reviewId',
            cwd: repo,
          );
        } on WorktreeException catch (e) {
          onError?.call(e);
        }
      }

      if (Directory(dir).existsSync()) {
        await bestEffort(['worktree', 'remove', '--force', dir]);
      }
      for (final ref in ['head', 'base']) {
        await bestEffort([
          'update-ref',
          '-d',
          'refs/roundtable-reviews/$reviewId/$ref',
        ]);
      }
    });
  }

  /// Lists every task worktree currently on disk, across all projects.
  List<({String projectId, String taskId})> listTaskWorktrees() {
    final root = Directory(workspaceRoot);
    if (!root.existsSync()) return const [];
    return [
      for (final project in root.listSync().whereType<Directory>())
        if (Directory('${project.path}/worktrees').existsSync())
          for (final worktree in Directory(
            '${project.path}/worktrees',
          ).listSync().whereType<Directory>())
            (
              projectId: project.uri.pathSegments
                  .where((s) => s.isNotEmpty)
                  .last,
              taskId: worktree.uri.pathSegments.where((s) => s.isNotEmpty).last,
            ),
    ];
  }

  /// Returns the worktree path for [taskId] if it currently exists on disk,
  /// else null.
  String? worktreePathIfExists({
    required String projectId,
    required String taskId,
  }) {
    final worktreeDir = _worktreeDir(projectId, taskId);
    return Directory(worktreeDir).existsSync() ? worktreeDir : null;
  }

  static void _assertSafeSegment(String value, {required String name}) {
    if (value.isEmpty || value.contains('/') || value.contains('..')) {
      throw ArgumentError.value(value, name, 'must not contain "/" or ".."');
    }
  }
}
