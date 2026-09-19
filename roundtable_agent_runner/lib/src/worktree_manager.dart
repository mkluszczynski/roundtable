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

/// Manages git-worktree-based execution isolation per project (design doc
/// §6.10): one bare clone per project on disk, and one worktree + branch per
/// task, so concurrent tasks on the same project never share a working
/// directory.
///
/// Disk layout under [workspaceRoot]:
/// ```
/// <workspaceRoot>/<projectId>/repo.git/            (bare clone)
/// <workspaceRoot>/<projectId>/worktrees/<taskId>/   (per-task worktree)
/// ```
///
/// Building the task-assignment loop that calls this class, and building an
/// authenticated clone URL from `Project.repoUrl`/`repoAccessToken`, are both
/// separate, not-yet-implemented pieces (design doc §6.1, §6.5) — this class
/// only accepts a ready-to-use [cloneUrl] and never logs or persists it
/// itself.
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

  /// Ensures a bare clone for [projectId] exists, cloning from [cloneUrl] if
  /// it doesn't. Idempotent — safe to call every time a task for this
  /// project starts.
  Future<void> ensureProjectCloned({
    required String projectId,
    required String cloneUrl,
  }) {
    _assertSafeSegment(projectId, name: 'projectId');
    return _lockFor(projectId).synchronized(() async {
      final repoDir = Directory(_bareRepoDir(projectId));
      if (repoDir.existsSync()) return;

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
    });
  }

  /// Creates an isolated worktree + branch (`task-<taskId>`) for [taskId]
  /// under project [projectId], or returns the existing one if it already
  /// exists on disk (a feedback iteration reuses the same worktree — design
  /// doc §6.10). Serialized per-project. Returns the absolute worktree path.
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
  /// cancelling a run mid-task — design doc §6.1). No-op if the worktree
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
