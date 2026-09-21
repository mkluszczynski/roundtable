import 'dart:async';
import 'dart:convert';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

TaskQuestion _question({int id = 1, String? answer}) => TaskQuestion(
  id: id,
  taskId: 1,
  question: 'Which approach?',
  options: const ['A', 'B'],
  answer: answer,
);

Task _task(TaskStatus status) =>
    Task(id: 1, projectId: 1, prompt: 'Do something', status: status);

void main() {
  group('PermissionPromptTool decision logic', () {
    test(
      'AskUserQuestion creates a question, blocks on the answer, then allows',
      () async {
        final createdQuestions = <Map<String, Object?>>[];
        final tool = PermissionPromptTool(
          taskId: 1,
          createQuestion: (taskId, question, options) async {
            createdQuestions.add({
              'taskId': taskId,
              'question': question,
              'options': options,
            });
            return _question();
          },
          watchAnswer: (questionId) =>
              Stream.value(_question(id: questionId, answer: 'A')),
          setPlanReady: (taskId, plan) async => _task(TaskStatus.planReady),
          watchPlanDecision: (taskId) => const Stream.empty(),
          latestFeedback: (taskId) async => null,
        );

        final decision = await tool.decide('AskUserQuestion', {
          'question': 'Which approach?',
          'options': ['A', 'B'],
        });

        expect(createdQuestions.single['question'], 'Which approach?');
        expect(createdQuestions.single['options'], ['A', 'B']);
        expect(decision.allow, isTrue);
        expect(decision.updatedInput, {
          'question': 'Which approach?',
          'options': ['A', 'B'],
          'answer': 'A',
        });
      },
    );

    test('AskUserQuestion extracts the first entry from a questions array and '
        'folds the answer back into it', () async {
      String? seenQuestion;
      List<String>? seenOptions;
      final tool = PermissionPromptTool(
        taskId: 1,
        createQuestion: (taskId, question, options) async {
          seenQuestion = question;
          seenOptions = options;
          return _question();
        },
        watchAnswer: (questionId) =>
            Stream.value(_question(id: questionId, answer: 'A')),
        setPlanReady: (taskId, plan) async => _task(TaskStatus.planReady),
        watchPlanDecision: (taskId) => const Stream.empty(),
        latestFeedback: (taskId) async => null,
      );

      final decision = await tool.decide('AskUserQuestion', {
        'questions': [
          {
            'question': 'Which approach?',
            'options': [
              {'label': 'A'},
              {'label': 'B'},
            ],
          },
        ],
      });

      expect(seenQuestion, 'Which approach?');
      expect(seenOptions, ['A', 'B']);
      expect(decision.allow, isTrue);
      final updatedQuestion = decision.updatedInput!['questions'].single as Map;
      expect(updatedQuestion['question'], 'Which approach?');
      expect(updatedQuestion['options'], [
        {'label': 'A'},
        {'label': 'B'},
      ]);
      expect(updatedQuestion['answer'], 'A');
    });

    test(
      'ExitPlanMode stores the plan, blocks on the decision, and allows when approved',
      () async {
        String? storedPlan;
        final tool = PermissionPromptTool(
          taskId: 1,
          createQuestion: (taskId, question, options) async => _question(),
          watchAnswer: (questionId) => const Stream.empty(),
          setPlanReady: (taskId, plan) async {
            storedPlan = plan;
            return _task(TaskStatus.planReady);
          },
          watchPlanDecision: (taskId) =>
              Stream.value(_task(TaskStatus.running)),
          latestFeedback: (taskId) async => null,
        );

        final decision = await tool.decide('ExitPlanMode', {
          'plan': 'Step 1, step 2',
        });

        expect(storedPlan, 'Step 1, step 2');
        expect(decision.allow, isTrue);
        expect(decision.updatedInput, {'plan': 'Step 1, step 2'});
      },
    );

    test(
      'ExitPlanMode denies with the latest feedback message when the dev asks for changes',
      () async {
        final tool = PermissionPromptTool(
          taskId: 1,
          createQuestion: (taskId, question, options) async => _question(),
          watchAnswer: (questionId) => const Stream.empty(),
          setPlanReady: (taskId, plan) async => _task(TaskStatus.planReady),
          watchPlanDecision: (taskId) =>
              Stream.value(_task(TaskStatus.planning)),
          latestFeedback: (taskId) async => TaskFeedback(
            taskId: taskId,
            message: 'Please reconsider the approach',
            phase: TaskFeedbackPhase.plan,
          ),
        );

        final decision = await tool.decide('ExitPlanMode', {'plan': 'Plan'});

        expect(decision.allow, isFalse);
        expect(decision.message, 'Please reconsider the approach');
      },
    );

    test('any other tool is auto-allowed with its input echoed back', () async {
      final tool = PermissionPromptTool(
        taskId: 1,
        createQuestion: (taskId, question, options) async => _question(),
        watchAnswer: (questionId) => const Stream.empty(),
        setPlanReady: (taskId, plan) async => _task(TaskStatus.planReady),
        watchPlanDecision: (taskId) => const Stream.empty(),
        latestFeedback: (taskId) async => null,
      );

      final decision = await tool.decide('Edit', {'file_path': 'README.md'});

      expect(decision.allow, isTrue);
      expect(decision.updatedInput, {'file_path': 'README.md'});
    });
  });

  group('runPermissionPromptToolServer (stdio wire protocol)', () {
    Future<List<Map<String, dynamic>>> run(
      List<Map<String, dynamic>> requests,
      PermissionPromptTool tool,
    ) async {
      final input = Stream<List<int>>.fromIterable(
        requests.map((r) => utf8.encode('${jsonEncode(r)}\n')),
      );
      final responses = <Map<String, dynamic>>[];

      await runPermissionPromptToolServer(
        tool,
        toolName: 'approval_prompt',
        serverName: 'roundtable-permission',
        input: input,
        output: (line) =>
            responses.add(jsonDecode(line) as Map<String, dynamic>),
      );

      return responses;
    }

    final passthroughTool = PermissionPromptTool(
      taskId: 1,
      createQuestion: (taskId, question, options) async => _question(),
      watchAnswer: (questionId) => const Stream.empty(),
      setPlanReady: (taskId, plan) async => _task(TaskStatus.planReady),
      watchPlanDecision: (taskId) => Stream.value(_task(TaskStatus.running)),
      latestFeedback: (taskId) async => null,
    );

    test('answers initialize and tools/list', () async {
      final responses = await run([
        {
          'jsonrpc': '2.0',
          'id': 0,
          'method': 'initialize',
          'params': <String, dynamic>{},
        },
        {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
        {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'},
      ], passthroughTool);

      expect(responses, hasLength(2));
      expect(
        responses[0]['result']['serverInfo']['name'],
        'roundtable-permission',
      );
      expect(responses[1]['result']['tools'].single['name'], 'approval_prompt');
    });

    test('answers tools/call with the decision JSON as text content', () async {
      final responses = await run([
        {
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/call',
          'params': {
            'name': 'approval_prompt',
            'arguments': {
              'tool_name': 'ExitPlanMode',
              'input': {'plan': 'Plan text'},
            },
          },
        },
      ], passthroughTool);

      expect(responses, hasLength(1));
      final content = responses.single['result']['content'].single;
      final decision = jsonDecode(content['text'] as String) as Map;
      expect(decision['behavior'], 'allow');
      expect(decision['updatedInput'], {'plan': 'Plan text'});
    });

    test(
      'a decide() failure denies instead of crashing the server, and later requests still get handled',
      () async {
        final throwingTool = PermissionPromptTool(
          taskId: 1,
          createQuestion: (taskId, question, options) async => _question(),
          watchAnswer: (questionId) => const Stream.empty(),
          setPlanReady: (taskId, plan) async =>
              throw StateError('server unreachable'),
          watchPlanDecision: (taskId) => const Stream.empty(),
          latestFeedback: (taskId) async => null,
        );

        final responses = await run([
          {
            'jsonrpc': '2.0',
            'id': 3,
            'method': 'tools/call',
            'params': {
              'name': 'approval_prompt',
              'arguments': {
                'tool_name': 'ExitPlanMode',
                'input': {'plan': 'Plan text'},
              },
            },
          },
          {
            'jsonrpc': '2.0',
            'id': 4,
            'method': 'tools/call',
            'params': {
              'name': 'approval_prompt',
              'arguments': {
                'tool_name': 'Edit',
                'input': {'file_path': 'README.md'},
              },
            },
          },
        ], throwingTool);

        expect(responses, hasLength(2));

        final failedDecision =
            jsonDecode(
                  responses[0]['result']['content'].single['text'] as String,
                )
                as Map;
        expect(failedDecision['behavior'], 'deny');
        expect(failedDecision['message'], contains('server unreachable'));

        final laterDecision =
            jsonDecode(
                  responses[1]['result']['content'].single['text'] as String,
                )
                as Map;
        expect(laterDecision['behavior'], 'allow');
      },
    );
  });
}
