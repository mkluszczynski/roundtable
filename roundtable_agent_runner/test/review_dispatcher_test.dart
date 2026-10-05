import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  group('parseReviewOutput', () {
    test('parses the last fenced json block', () {
      final result = parseReviewOutput('''
I looked around.

```json
{"summary": "draft", "comments": []}
```

Final answer:

```json
{
  "summary": "Mostly fine.",
  "comments": [
    {"path": "lib/a.dart", "line": 3, "severity": "blocker", "body": "Crash on null"},
    {"path": "README.md", "line": null, "severity": "nit", "body": "Typo"}
  ]
}
```
''');

      expect(result, isNotNull);
      expect(result!.summary, 'Mostly fine.');
      expect(result.comments, hasLength(2));
      expect(result.comments[0].path, 'lib/a.dart');
      expect(result.comments[0].line, 3);
      expect(result.comments[0].severity, ReviewCommentSeverity.blocker);
      expect(result.comments[1].line, isNull);
      expect(result.comments[1].severity, ReviewCommentSeverity.nit);
    });

    test('accepts bare JSON', () {
      final result = parseReviewOutput('{"summary": "LGTM", "comments": []}');
      expect(result!.summary, 'LGTM');
      expect(result.comments, isEmpty);
    });

    test('defaults an unknown severity to issue and skips invalid items', () {
      final result = parseReviewOutput('''```json
{"summary": "s", "comments": [
  {"path": "a.dart", "line": 0, "severity": "critical", "body": "x"},
  {"line": 4, "body": "no path"},
  "not an object"
]}
```''');
      expect(result!.comments, hasLength(1));
      expect(result.comments.single.severity, ReviewCommentSeverity.issue);
      expect(result.comments.single.line, isNull);
    });

    test('returns null without valid JSON', () {
      expect(parseReviewOutput('No JSON here.'), isNull);
      expect(parseReviewOutput('```json\n{not json}\n```'), isNull);
      expect(parseReviewOutput('```json\n{"summary": 1}\n```'), isNull);
    });
  });

  test('buildReviewPrompt includes the task and the diff base', () {
    final prompt = buildReviewPrompt(
      rolePrompt: 'You are Ana.',
      taskPrompt: 'Add a login page',
      baseSha: 'abc123',
    );
    expect(prompt, contains('You are Ana.'));
    expect(prompt, contains('Add a login page'));
    expect(prompt, contains('git diff abc123...HEAD'));
    expect(prompt, contains('```json'));
    expect(prompt, isNot(contains('image(s)')));
  });

  test('buildReviewPrompt lists the task\'s attached images', () {
    final prompt = buildReviewPrompt(
      rolePrompt: 'You are Ana.',
      taskPrompt: 'Match the mockup',
      baseSha: 'abc123',
      imagePaths: ['/tmp/r/1-a.png', '/tmp/r/2-b.png'],
    );
    expect(prompt, contains('2 image(s)'));
    expect(prompt, contains('Read tool'));
    expect(prompt, contains('- /tmp/r/1-a.png\n- /tmp/r/2-b.png'));
    expect(prompt, contains('git diff abc123...HEAD'));
  });

  group('ReviewDispatcher.handle', () {
    late Directory tempDir;
    late Directory fixtureRepo;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('review_dispatcher_test_');
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
      await _git(fixtureRepo.path, ['checkout', '-b', 'task-1']);
      File('${fixtureRepo.path}/header.txt').writeAsStringSync('new\n');
      await _git(fixtureRepo.path, ['add', '.']);
      await _git(fixtureRepo.path, ['commit', '-m', 'change']);
      await _git(fixtureRepo.path, ['checkout', 'main']);
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    /// A fake `claude` that records its arguments to `args.txt` and the
    /// contents of each `--add-dir` (while it runs) to `listing.txt`, then
    /// returns an empty verdict.
    String writeFakeClaude() {
      final script = File('${tempDir.path}/fake_claude.sh');
      script.writeAsStringSync(
        "#!/bin/sh\nout='${tempDir.path}'\n"
        r"""
printf '%s\n' "$@" > "$out/args.txt"
prev=
for a in "$@"; do
  if [ "$prev" = "--add-dir" ]; then ls "$a" >> "$out/listing.txt"; fi
  prev=$a
done
echo '{"type":"result","subtype":"success","session_id":"s","result":"{\"summary\":\"Looks good.\",\"comments\":[]}"}'
exit 0
""",
      );
      Process.runSync('chmod', ['+x', script.path]);
      return script.path;
    }

    ReviewDispatcher buildDispatcher({
      required List<int> fetchedFor,
      required List<String> completed,
      required List<String> failed,
    }) {
      final script = writeFakeClaude();
      return ReviewDispatcher(
        worktreeManager: WorktreeManager(
          workspaceRoot: '${tempDir.path}/workspace',
        ),
        executorFactory: () => ClaudeCodeExecutor(executable: script),
        oauthToken: null,
        getCloneUrl: (_) async => fixtureRepo.path,
        fetchAgent: (id) async => Agent(
          id: id,
          machineId: 1,
          name: 'Ana',
          role: AgentRoleDefinition(
            name: 'backend',
            prompt: 'You are {name}, the backend specialist.',
          ),
          status: AgentStatus.idle,
        ),
        startReview: (_) async => Task(
          id: 1,
          projectId: 1,
          agentId: 1,
          prompt: 'Match the mockup',
          skipPlanning: true,
          status: TaskStatus.awaitingReview,
          branchName: 'task-1',
        ),
        completeReview: (_, summary, _) async => completed.add(summary),
        failReview: (_, reason) async => failed.add(reason),
        appendLog: (_) async {},
        log: (_) {},
        fetchAttachments: (taskId) async {
          fetchedFor.add(taskId);
          return [
            (fileName: 'mockup.png', bytes: [1, 2, 3]),
          ];
        },
      );
    }

    test('gives the reviewer the task\'s attached images and removes them '
        'afterwards', () async {
      final fetchedFor = <int>[];
      final completed = <String>[];
      final failed = <String>[];
      final dispatcher = buildDispatcher(
        fetchedFor: fetchedFor,
        completed: completed,
        failed: failed,
      );

      await dispatcher.handle(
        CodeReview(
          id: 7,
          taskId: 1,
          reviewerAgentId: 2,
          status: CodeReviewStatus.queued,
        ),
      );

      expect(failed, isEmpty);
      expect(completed, ['Looks good.']);
      expect(fetchedFor, [1]);

      final args = File('${tempDir.path}/args.txt').readAsLinesSync();
      final addDir = args[args.indexOf('--add-dir') + 1];
      final imagePath = '$addDir/1-mockup.png';
      // The prompt spans several lines of args.txt.
      expect(args, anyElement(contains('1 image(s)')));
      expect(args, contains('- $imagePath'));

      // The image was on disk while the reviewer ran, and is gone now.
      expect(
        File('${tempDir.path}/listing.txt').readAsStringSync(),
        contains('1-mockup.png'),
      );
      expect(Directory(addDir).existsSync(), isFalse);
    });
  });
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
}
