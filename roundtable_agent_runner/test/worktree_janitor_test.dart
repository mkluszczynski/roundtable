import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  group('WorktreeJanitor', () {
    late Directory tempDir;
    late WorktreeManager manager;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('worktree_janitor_test_');
      final origin = Directory('${tempDir.path}/origin')..createSync();
      Future<void> git(List<String> args) async {
        final r = await Process.run('git', args, workingDirectory: origin.path);
        if (r.exitCode != 0) throw StateError('git $args: ${r.stderr}');
      }

      await git(['init', '-b', 'main']);
      await git(['config', 'user.email', 'test@example.com']);
      await git(['config', 'user.name', 'Test']);
      File('${origin.path}/README.md').writeAsStringSync('hello\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'initial']);

      manager = WorktreeManager(workspaceRoot: '${tempDir.path}/workspace');
      await manager.ensureProjectCloned(projectId: '1', cloneUrl: origin.path);
      for (final id in ['10', '11', '12', '13', '14', '15']) {
        await manager.createWorktree(projectId: '1', taskId: id);
      }
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    Task task(int id, TaskStatus status, {String? branchName}) => Task(
      id: id,
      projectId: 1,
      prompt: 'x',
      status: status,
      branchName: branchName,
    );

    test('removes worktrees of deleted, done, and never-pushed failed tasks, '
        'and keeps live, pushed-failed, and in-flight ones', () async {
      final janitor = WorktreeJanitor(
        worktreeManager: manager,
        findTasks: (ids) async => [
          // 10 is missing: the task was deleted.
          task(11, TaskStatus.done, branchName: 'task-11'),
          task(12, TaskStatus.failed),
          task(13, TaskStatus.failed, branchName: 'task-13'),
          task(14, TaskStatus.awaitingReview, branchName: 'task-14'),
          task(15, TaskStatus.cancelled),
        ],
        isActive: (id) => id == 15,
        log: (_) {},
      );

      await janitor.sweep();

      String? path(String id) =>
          manager.worktreePathIfExists(projectId: '1', taskId: id);
      expect(path('10'), isNull);
      expect(path('11'), isNull);
      expect(path('12'), isNull);
      expect(path('13'), isNotNull);
      expect(path('14'), isNotNull);
      expect(path('15'), isNotNull);
    });

    test('lists every task worktree on disk', () {
      expect(manager.listTaskWorktrees().map((w) => w.taskId).toSet(), {
        '10',
        '11',
        '12',
        '13',
        '14',
        '15',
      });
    });
  });
}
