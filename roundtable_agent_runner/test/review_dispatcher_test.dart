import 'dart:async';
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

    test('parses the verdict', () {
      expect(
        parseReviewOutput(
          '{"verdict": "approve", "summary": "s", "comments": []}',
        )!.verdict,
        CodeReviewVerdict.approve,
      );
      expect(
        parseReviewOutput(
          '{"verdict": "changes_requested", "summary": "s", "comments": []}',
        )!.verdict,
        CodeReviewVerdict.changesRequested,
      );
      expect(
        parseReviewOutput(
          '{"verdict": "maybe", "summary": "s", "comments": []}',
        )!.verdict,
        isNull,
      );
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

    test('parses the checks of earlier comments', () {
      final result = parseReviewOutput('''```json
{"summary": "s", "comments": [], "previous": [
  {"id": 4, "fixed": true, "note": null},
  {"id": 5, "fixed": false, "note": "Still crashes on null"},
  {"id": "x", "fixed": true},
  {"id": 6}
]}
```''');
      expect(result!.checks, hasLength(2));
      expect(result.checks[0].commentId, 4);
      expect(result.checks[0].fixed, isTrue);
      expect(result.checks[0].note, isNull);
      expect(result.checks[1].fixed, isFalse);
      expect(result.checks[1].note, 'Still crashes on null');
      expect(
        parseReviewOutput('{"summary": "s", "comments": []}')!.checks,
        isEmpty,
      );
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
    expect(prompt, contains('AGENTS.md'));
    expect(prompt, contains('blocker: a bug'));
    expect(prompt, contains('pick the lower one'));
    expect(prompt, isNot(contains('image(s)')));
  });

  test('buildReviewPrompt lists earlier comments to check', () {
    final prompt = buildReviewPrompt(
      rolePrompt: 'You are Ana.',
      taskPrompt: 'Add a login page',
      baseSha: 'abc123',
      previousComments: [
        ReviewComment(
          id: 4,
          reviewId: 1,
          path: 'lib/a.dart',
          line: 3,
          body: 'Crash on null',
          severity: ReviewCommentSeverity.blocker,
          state: ReviewCommentState.resolved,
        ),
        ReviewComment(
          id: 5,
          reviewId: 1,
          path: 'README.md',
          body: 'Typo',
          severity: ReviewCommentSeverity.nit,
          state: ReviewCommentState.dismissed,
        ),
      ],
    );
    expect(prompt, contains('reviewed before'));
    expect(
      prompt,
      contains(
        '- id 4 · lib/a.dart:3 · blocker · the agent was asked to fix it',
      ),
    );
    expect(prompt, contains('- id 5 · README.md · nit · dismissed'));
    expect(prompt, contains('"previous"'));
    expect(
      buildReviewPrompt(rolePrompt: 'r', taskPrompt: 't', baseSha: 'b'),
      isNot(contains('"previous"')),
    );
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
      AgentExecutionMode executionMode = AgentExecutionMode.native,
      ContainerSandbox Function(ContainerRequest request)? sandboxFor,
      List<bool>? containerPrompts,
      AgentWorkQueue? workQueue,
      List<int>? started,
      List<String>? events,
      UsageLimitGate? usageLimit,
      Future<void> Function(int reviewId)? requeueReview,
    }) {
      final script = writeFakeClaude();
      return ReviewDispatcher(
        usageLimit: usageLimit,
        requeueReview: requeueReview,
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
          executionMode: executionMode,
        ),
        workQueue: workQueue,
        startReview: (reviewId) async {
          started?.add(reviewId);
          return Task(
            id: 1,
            projectId: 1,
            agentId: 1,
            prompt: 'Match the mockup',
            skipPlanning: true,
            status: TaskStatus.awaitingReview,
            branchName: 'task-1',
          );
        },
        completeReview: (_, findings) async => completed.add(findings.summary),
        failReview: (_, reason) async => failed.add(reason),
        appendLog: (entry) async => events?.add(entry.content),
        log: (_) {},
        fetchProject: (id) async => Project(
          id: id,
          name: 'Demo',
          repoUrl: 'https://github.com/o/demo',
          dockerImage: 'my/image:1',
        ),
        sandboxFor: sandboxFor,
        environmentPrompt: ({container = false}) {
          containerPrompts?.add(container);
          return 'ENV';
        },
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
      expect(
        args[args.indexOf('--allowedTools') + 1],
        startsWith('Read,Grep,Glob,Bash(git diff:*)'),
        reason: 'on the host the reviewer only reads',
      );
      expect(args, anyElement(contains("can't run commands here")));

      // The image was on disk while the reviewer ran, and is gone now.
      expect(
        File('${tempDir.path}/listing.txt').readAsStringSync(),
        contains('1-mockup.png'),
      );
      expect(Directory(addDir).existsSync(), isFalse);
    });

    test('runs a docker-mode reviewer in its own container', () async {
      final podmanArgs = '${tempDir.path}/podman-args.txt';
      final podman = File('${tempDir.path}/podman')
        ..writeAsStringSync('''#!/bin/sh
echo "\$@" >> $podmanArgs
[ "\$3" = "rm" ] && exit 0
while [ "\$1" != "my/image:1" ]; do shift; done
shift
exec "\$@"
''');
      Process.runSync('chmod', ['+x', podman.path]);
      ContainerRequest? request;
      final completed = <String>[];
      final failed = <String>[];
      final containerPrompts = <bool>[];
      late String claude;
      final dispatcher = buildDispatcher(
        fetchedFor: [],
        completed: completed,
        failed: failed,
        executionMode: AgentExecutionMode.docker,
        containerPrompts: containerPrompts,
        sandboxFor: (r) {
          request = r;
          return ContainerSandbox(
            image: r.image!,
            name: r.name,
            workingDirectory: r.worktreePath,
            mounts: [(path: r.worktreePath, readOnly: false)],
            home: '${tempDir.path}/chome',
            claudePath: claude,
            podman: podman.path,
          );
        },
      );
      claude = '${tempDir.path}/fake_claude.sh';

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
      expect(request!.name, 'roundtable-review-7');
      expect(request!.projectId, 1);
      expect(request!.worktreePath, endsWith('/reviews/7'));
      expect(
        request!.readOnlyDirectories,
        hasLength(1),
        reason: 'the attached images are mounted read-only',
      );
      expect(containerPrompts, [true]);
      final podmanCall = File(podmanArgs).readAsStringSync();
      expect(podmanCall, contains('--userns=keep-id'));
      expect(podmanCall, contains('my/image:1 $claude'));
      expect(podmanCall, contains('rm --force --ignore roundtable-review-7'));
      final args = File('${tempDir.path}/args.txt').readAsLinesSync();
      expect(
        args[args.indexOf('--allowedTools') + 1],
        'Read,Grep,Glob,Bash',
        reason: 'a containerized reviewer may run the project checks',
      );
      expect(args, contains('Edit,Write,NotebookEdit'));
      expect(args, anyElement(contains("Verify, don't guess")));
    });

    test('waits while the reviewer is busy with its own task', () async {
      final queue = AgentWorkQueue();
      final release = Completer<void>();
      final busy = queue.run(2, 'task #9', () => release.future);
      final started = <int>[];
      final events = <String>[];
      final completed = <String>[];
      final handled =
          buildDispatcher(
            fetchedFor: [],
            completed: completed,
            failed: [],
            workQueue: queue,
            started: started,
            events: events,
          ).handle(
            CodeReview(
              id: 7,
              taskId: 1,
              reviewerAgentId: 2,
              status: CodeReviewStatus.queued,
            ),
          );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(started, isEmpty, reason: 'the review stays queued');
      expect(events, ['Review waiting — the reviewer is busy with task #9']);

      release.complete();
      await busy;
      await handled;
      expect(started, [7]);
      expect(completed, ['Looks good.']);
    });

    test('waits for the usage limit to reset before starting', () async {
      final gate = UsageLimitGate()
        ..hit(DateTime.now().add(const Duration(milliseconds: 100)));
      final started = <int>[];
      final events = <String>[];
      await buildDispatcher(
        fetchedFor: [],
        completed: [],
        failed: [],
        usageLimit: gate,
        started: started,
        events: events,
      ).handle(
        CodeReview(
          id: 7,
          taskId: 1,
          reviewerAgentId: 2,
          status: CodeReviewStatus.queued,
        ),
      );
      expect(events.first, startsWith('Review waiting for the Claude usage'));
      expect(started, [7]);
    });

    test('a review cut short by the usage limit is queued again and runs '
        'after the reset', () async {
      var clock = DateTime.now();
      final gate = UsageLimitGate(now: () => clock);
      final started = <int>[];
      final completed = <String>[];
      final failed = <String>[];
      final requeued = <int>[];
      final dispatcher = buildDispatcher(
        fetchedFor: [],
        completed: completed,
        failed: failed,
        usageLimit: gate,
        started: started,
        requeueReview: (id) async {
          requeued.add(id);
          // The limit resets and the next run succeeds.
          clock = DateTime.now().add(const Duration(days: 2));
          writeFakeClaude();
        },
      );
      File('${tempDir.path}/fake_claude.sh').writeAsStringSync(
        '#!/bin/sh\n'
        r'''echo '{"type":"result","subtype":"error_during_execution","session_id":"s","result":"You have hit your session limit · resets 3pm"}'
exit 1
''',
      );

      await dispatcher.handle(
        CodeReview(
          id: 7,
          taskId: 1,
          reviewerAgentId: 2,
          status: CodeReviewStatus.queued,
        ),
      );

      expect(requeued, [7]);
      expect(failed, isEmpty);
      expect(started, [7, 7]);
      expect(completed, ['Looks good.']);
    });

    test('fails a docker-mode review on a machine without podman', () async {
      final completed = <String>[];
      final failed = <String>[];
      await buildDispatcher(
        fetchedFor: [],
        completed: completed,
        failed: failed,
        executionMode: AgentExecutionMode.docker,
      ).handle(
        CodeReview(
          id: 8,
          taskId: 1,
          reviewerAgentId: 2,
          status: CodeReviewStatus.queued,
        ),
      );

      expect(completed, isEmpty);
      expect(failed.single, contains('docker mode'));
    });
  });
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
}
