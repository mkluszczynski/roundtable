import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  group('WorktreeManager', () {
    late Directory tempDir;
    late Directory fixtureRepo;
    late WorktreeManager manager;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('worktree_manager_test_');
      fixtureRepo = Directory('${tempDir.path}/fixture_origin');
      await fixtureRepo.create();
      await _git(fixtureRepo.path, ['init', '-b', 'main']);
      await _git(fixtureRepo.path, [
        'config',
        'user.email',
        'test@example.com',
      ]);
      await _git(fixtureRepo.path, ['config', 'user.name', 'Test']);
      File('${fixtureRepo.path}/README.md').writeAsStringSync('hello\n');
      await _git(fixtureRepo.path, ['add', '.']);
      await _git(fixtureRepo.path, ['commit', '-m', 'initial']);

      manager = WorktreeManager(workspaceRoot: '${tempDir.path}/workspace');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test(
      'ensureProjectCloned creates a bare clone and is idempotent',
      () async {
        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );
        final repoGit = Directory('${tempDir.path}/workspace/p1/repo.git');
        expect(repoGit.existsSync(), isTrue);

        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );
        expect(repoGit.existsSync(), isTrue);
      },
    );

    test('createWorktree produces an isolated dir on its own branch', () async {
      await manager.ensureProjectCloned(
        projectId: 'p1',
        cloneUrl: fixtureRepo.path,
      );
      final path = await manager.createWorktree(projectId: 'p1', taskId: 't1');

      expect(Directory(path).existsSync(), isTrue);
      final branch = await _gitOutput(path, [
        'rev-parse',
        '--abbrev-ref',
        'HEAD',
      ]);
      expect(branch.trim(), 'task-t1');
    });

    test(
      'createWorktree is idempotent for an already-existing task worktree',
      () async {
        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );
        final first = await manager.createWorktree(
          projectId: 'p1',
          taskId: 't1',
        );
        final second = await manager.createWorktree(
          projectId: 'p1',
          taskId: 't1',
        );
        expect(second, equals(first));
      },
    );

    test(
      'concurrent createWorktree calls for two tasks on the same project '
      'both succeed, stay isolated, and both appear in worktree list',
      () async {
        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );

        final results = await Future.wait([
          manager.createWorktree(projectId: 'p1', taskId: 'task-a'),
          manager.createWorktree(projectId: 'p1', taskId: 'task-b'),
        ]);
        final pathA = results[0];
        final pathB = results[1];

        expect(pathA, isNot(equals(pathB)));
        expect(Directory(pathA).existsSync(), isTrue);
        expect(Directory(pathB).existsSync(), isTrue);

        File('$pathA/a.txt').writeAsStringSync('from a');
        await _git(pathA, ['add', '.']);
        await _git(pathA, ['commit', '-m', 'commit on a']);

        File('$pathB/b.txt').writeAsStringSync('from b');
        await _git(pathB, ['add', '.']);
        await _git(pathB, ['commit', '-m', 'commit on b']);

        expect(File('$pathA/b.txt').existsSync(), isFalse);
        expect(File('$pathB/a.txt').existsSync(), isFalse);

        final logA = await _gitOutput(pathA, ['log', '--oneline']);
        final logB = await _gitOutput(pathB, ['log', '--oneline']);
        expect(logA, isNot(contains('commit on b')));
        expect(logB, isNot(contains('commit on a')));

        final repoGitDir = '${tempDir.path}/workspace/p1/repo.git';
        final list = await _gitOutput(repoGitDir, ['worktree', 'list']);
        expect(list, contains('task-a'));
        expect(list, contains('task-b'));
      },
    );

    test('removeWorktree removes the directory and branch', () async {
      await manager.ensureProjectCloned(
        projectId: 'p1',
        cloneUrl: fixtureRepo.path,
      );
      final path = await manager.createWorktree(projectId: 'p1', taskId: 't1');
      await manager.removeWorktree(projectId: 'p1', taskId: 't1');

      expect(Directory(path).existsSync(), isFalse);
      expect(
        manager.worktreePathIfExists(projectId: 'p1', taskId: 't1'),
        isNull,
      );

      final repoGitDir = '${tempDir.path}/workspace/p1/repo.git';
      final branches = await _gitOutput(repoGitDir, ['branch', '--list']);
      expect(branches, isNot(contains('task-t1')));
    });

    test(
      'removeWorktree is a no-op when the worktree does not exist',
      () async {
        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );
        await manager.removeWorktree(projectId: 'p1', taskId: 'never-created');
      },
    );

    test('resetWorktree discards uncommitted changes', () async {
      await manager.ensureProjectCloned(
        projectId: 'p1',
        cloneUrl: fixtureRepo.path,
      );
      final path = await manager.createWorktree(projectId: 'p1', taskId: 't1');
      File('$path/dirty.txt').writeAsStringSync('uncommitted');

      await manager.resetWorktree(projectId: 'p1', taskId: 't1');

      expect(File('$path/dirty.txt').existsSync(), isFalse);
    });

    test(
      'commitAndPush commits and pushes when the worktree has changes',
      () async {
        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );
        final path = await manager.createWorktree(
          projectId: 'p1',
          taskId: 't1',
        );
        File('$path/new.txt').writeAsStringSync('new content');

        final committed = await manager.commitAndPush(
          projectId: 'p1',
          taskId: 't1',
          commitMessage: 'add new.txt',
          pushUrl: fixtureRepo.path,
        );

        expect(committed, isTrue);
        final log = await _gitOutput(fixtureRepo.path, [
          'log',
          '--oneline',
          'task-t1',
        ]);
        expect(log, contains('add new.txt'));
      },
    );

    test(
      'commitAndPush returns false without committing when the worktree is clean',
      () async {
        await manager.ensureProjectCloned(
          projectId: 'p1',
          cloneUrl: fixtureRepo.path,
        );
        await manager.createWorktree(projectId: 'p1', taskId: 't1');

        final committed = await manager.commitAndPush(
          projectId: 'p1',
          taskId: 't1',
          commitMessage: 'nothing to commit',
          pushUrl: fixtureRepo.path,
        );

        expect(committed, isFalse);
        final branches = await _gitOutput(fixtureRepo.path, [
          'branch',
          '--list',
        ]);
        expect(branches, isNot(contains('task-t1')));
      },
    );

    test('rejects projectId/taskId containing path separators', () {
      expect(
        () => manager.createWorktree(projectId: '../evil', taskId: 't1'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => manager.createWorktree(projectId: 'p1', taskId: '../evil'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
}

Future<String> _gitOutput(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout.toString();
}
