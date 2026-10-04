import 'dart:io';

import 'package:synchronized/synchronized.dart';

/// Thrown when a git invocation made by [WorktreeManager] fails.
class WorktreeException implements Exception {
  WorktreeException(this.message, {required this.stderr});

  final String message;
  final String stderr;

  @override
  String toString() => '$message: $stderr';
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

  /// Ensures a bare clone for [projectId] exists, cloning from [cloneUrl] if
  /// it doesn't, then fetches the remote's current default branch into
  /// [baseRef]. Without the fetch every task would branch from the commit
  /// the project had when it was first cloned on this machine. Idempotent —
  /// safe to call every time a task for this project starts.
  Future<void> ensureProjectCloned({
    required String projectId,
    required String cloneUrl,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    return _lockFor(projectId).synchronized(() async {
      final repoDir = Directory(_bareRepoDir(projectId));
      if (!repoDir.existsSync()) {
        await Directory(_projectDir(projectId)).create(recursive: true);
        final result = await Process.run('git', [
          'clone',
          '--bare',
          cloneUrl,
          repoDir.path,
        ]);
        if (result.exitCode != 0) {
          throw WorktreeException(
            'git clone --bare failed for project $projectId',
            stderr: result.stderr.toString(),
          );
        }
      }

      final fetch = await Process.run('git', [
        'fetch',
        cloneUrl,
        '+HEAD:$baseRef',
      ], workingDirectory: repoDir.path);
      if (fetch.exitCode != 0) {
        throw WorktreeException(
          'git fetch of the default branch failed for project $projectId',
          stderr: fetch.stderr.toString(),
        );
      }
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
      final worktreeDir = Directory(_worktreeDir(projectId, taskId));
      if (worktreeDir.existsSync()) {
        return worktreeDir.path;
      }

      await Directory(
        '${_projectDir(projectId)}/worktrees',
      ).create(recursive: true);
      final result = await Process.run('git', [
        'worktree',
        'add',
        worktreeDir.path,
        '-b',
        'task-$taskId',
        // Branch from the freshly fetched default branch (see
        // [ensureProjectCloned]), not the bare clone's stale HEAD.
        baseRef,
      ], workingDirectory: _bareRepoDir(projectId));
      if (result.exitCode != 0) {
        throw WorktreeException(
          'git worktree add failed for task $taskId on project $projectId',
          stderr: result.stderr.toString(),
        );
      }
      return worktreeDir.path;
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

      final reset = await Process.run('git', [
        'reset',
        '--hard',
      ], workingDirectory: worktreeDir);
      if (reset.exitCode != 0) {
        throw WorktreeException(
          'git reset --hard failed for task $taskId on project $projectId',
          stderr: reset.stderr.toString(),
        );
      }

      final clean = await Process.run('git', [
        'clean',
        '-fd',
      ], workingDirectory: worktreeDir);
      if (clean.exitCode != 0) {
        throw WorktreeException(
          'git clean -fd failed for task $taskId on project $projectId',
          stderr: clean.stderr.toString(),
        );
      }
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
      final worktreeDir = Directory(_worktreeDir(projectId, taskId));
      if (!worktreeDir.existsSync()) return;

      final remove = await Process.run('git', [
        'worktree',
        'remove',
        '--force',
        worktreeDir.path,
      ], workingDirectory: _bareRepoDir(projectId));
      if (remove.exitCode != 0) {
        throw WorktreeException(
          'git worktree remove failed for task $taskId on project $projectId',
          stderr: remove.stderr.toString(),
        );
      }

      final prune = await Process.run('git', [
        'worktree',
        'prune',
      ], workingDirectory: _bareRepoDir(projectId));
      if (prune.exitCode != 0) {
        throw WorktreeException(
          'git worktree prune failed for project $projectId',
          stderr: prune.stderr.toString(),
        );
      }

      final deleteBranch = await Process.run('git', [
        'branch',
        '-D',
        'task-$taskId',
      ], workingDirectory: _bareRepoDir(projectId));
      if (deleteBranch.exitCode != 0) {
        throw WorktreeException(
          'git branch -D failed for task $taskId on project $projectId',
          stderr: deleteBranch.stderr.toString(),
        );
      }
    });
  }

  /// Commits any pending changes in the task's worktree and pushes the
  /// resulting branch to [pushUrl] (docs/FLOWS.md §4). Returns `false`
  /// without committing or pushing if the worktree has no changes — nothing
  /// for the agent to have done. [pushUrl] is used as a one-off push target,
  /// never stored as a named git remote, so any credentials embedded in it
  /// never touch git config on disk (docs/ARCHITECTURE.md).
  Future<bool> commitAndPush({
    required String projectId,
    required String taskId,
    required String commitMessage,
    required String pushUrl,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(taskId, name: 'taskId');
    return _lockFor(projectId).synchronized(() async {
      final worktreeDir = _worktreeDir(projectId, taskId);
      if (!Directory(worktreeDir).existsSync()) {
        throw WorktreeException(
          'no worktree for task $taskId on project $projectId',
          stderr: '',
        );
      }

      final add = await Process.run('git', [
        'add',
        '-A',
      ], workingDirectory: worktreeDir);
      if (add.exitCode != 0) {
        throw WorktreeException(
          'git add failed for task $taskId on project $projectId',
          stderr: add.stderr.toString(),
        );
      }

      final status = await Process.run('git', [
        'status',
        '--porcelain',
      ], workingDirectory: worktreeDir);
      if (status.exitCode != 0) {
        throw WorktreeException(
          'git status failed for task $taskId on project $projectId',
          stderr: status.stderr.toString(),
        );
      }
      if (status.stdout.toString().trim().isEmpty) {
        return false;
      }

      final commit = await Process.run('git', [
        '-c',
        'user.name=Roundtable Agent',
        '-c',
        'user.email=agent@roundtable.local',
        'commit',
        '-m',
        commitMessage,
      ], workingDirectory: worktreeDir);
      if (commit.exitCode != 0) {
        throw WorktreeException(
          'git commit failed for task $taskId on project $projectId',
          stderr: commit.stderr.toString(),
        );
      }

      final push = await Process.run('git', [
        'push',
        pushUrl,
        'HEAD:refs/heads/task-$taskId',
      ], workingDirectory: worktreeDir);
      if (push.exitCode != 0) {
        throw WorktreeException(
          'git push failed for task $taskId on project $projectId',
          stderr: push.stderr.toString(),
        );
      }

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
    return _lockFor(projectId).synchronized(() async {
      final repo = _bareRepoDir(projectId);
      final headRef = 'refs/roundtable-reviews/$reviewId/head';
      final baseRef = 'refs/roundtable-reviews/$reviewId/base';

      Future<String> git(List<String> args, {String? cwd}) async {
        final result = await Process.run(
          'git',
          args,
          workingDirectory: cwd ?? repo,
        );
        if (result.exitCode != 0) {
          throw WorktreeException(
            'git ${args.first} failed for review $reviewId on project $projectId',
            stderr: result.stderr.toString(),
          );
        }
        return result.stdout.toString().trim();
      }

      await git([
        'fetch',
        fetchUrl,
        '+refs/heads/$branch:$headRef',
        '+HEAD:$baseRef',
      ]);

      final dir = Directory(_reviewDir(projectId, reviewId));
      if (dir.existsSync()) {
        await git(['worktree', 'remove', '--force', dir.path]);
      }
      await Directory(
        '${_projectDir(projectId)}/reviews',
      ).create(recursive: true);
      await git(['worktree', 'add', '--detach', dir.path, headRef]);

      final baseSha = await git(['merge-base', baseRef, headRef]);
      return (path: dir.path, baseSha: baseSha);
    });
  }

  /// Removes [reviewId]'s worktree and refs. Idempotent.
  Future<void> removeReviewWorktree({
    required String projectId,
    required String reviewId,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    _assertSafeSegment(reviewId, name: 'reviewId');
    return _lockFor(projectId).synchronized(() async {
      final repo = _bareRepoDir(projectId);
      final dir = Directory(_reviewDir(projectId, reviewId));
      if (dir.existsSync()) {
        await Process.run('git', [
          'worktree',
          'remove',
          '--force',
          dir.path,
        ], workingDirectory: repo);
      }
      for (final ref in ['head', 'base']) {
        await Process.run('git', [
          'update-ref',
          '-d',
          'refs/roundtable-reviews/$reviewId/$ref',
        ], workingDirectory: repo);
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
