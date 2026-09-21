import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:roundtable_client/roundtable_client.dart';

/// The `{"behavior": ...}` JSON an MCP permission-prompt-tool call must
/// answer with (design doc §6.4), confirmed against the real `claude` CLI by
/// a manual spike: `allow` must echo back a valid `updatedInput` (the tool's
/// original input, unless deliberately rewritten), `deny` carries the reason
/// Claude Code reports back to the model (folded into `ExitPlanMode`'s next
/// attempt as plan feedback, per §6.4).
class PermissionDecision {
  const PermissionDecision.allow({Map<String, dynamic>? updatedInput})
    : allow = true,
      updatedInput = updatedInput ?? const {},
      message = null;

  const PermissionDecision.deny(this.message)
    : allow = false,
      updatedInput = null;

  final bool allow;
  final Map<String, dynamic>? updatedInput;
  final String? message;

  Map<String, dynamic> toJson() => allow
      ? {'behavior': 'allow', 'updatedInput': updatedInput}
      : {'behavior': 'deny', 'message': message};
}

/// Decision logic for the `--permission-prompt-tool` MCP tool (design doc
/// §6.4), kept free of any MCP/stdio transport concerns so it's testable
/// with injected fakes instead of a real [Client] — mirrors the
/// `TaskDispatcher` dependency-injection style.
///
/// Confirmed by a manual spike against the real `claude` CLI: in
/// `--permission-mode plan`, this tool is called for *every* non-read-only
/// tool, not just `AskUserQuestion`/`ExitPlanMode` — once a plan is
/// approved, the same process continues straight into implementation, so
/// [decide]'s default branch must auto-allow (mirroring execution-phase's
/// `--permission-prompts none` "fully unattended" intent).
class PermissionPromptTool {
  PermissionPromptTool({
    required this.taskId,
    required this.createQuestion,
    required this.watchAnswer,
    required this.setPlanReady,
    required this.watchPlanDecision,
    required this.latestFeedback,
  });

  final int taskId;
  final Future<TaskQuestion> Function(
    int taskId,
    String question,
    List<String> options,
  )
  createQuestion;
  final Stream<TaskQuestion> Function(int questionId) watchAnswer;
  final Future<Task> Function(int taskId, String plan) setPlanReady;
  final Stream<Task> Function(int taskId) watchPlanDecision;
  final Future<TaskFeedback?> Function(int taskId) latestFeedback;

  Future<PermissionDecision> decide(
    String toolName,
    Map<String, dynamic> input,
  ) async {
    switch (toolName) {
      case 'AskUserQuestion':
        return _decideAskUserQuestion(input);
      case 'ExitPlanMode':
        return _decideExitPlanMode(input);
      default:
        // Plan mode routes every non-read-only tool call through this
        // permission tool once a plan is approved — auto-allow anything
        // that isn't a question/plan gate, so execution proceeds
        // unattended.
        return PermissionDecision.allow(updatedInput: input);
    }
  }

  Future<PermissionDecision> _decideAskUserQuestion(
    Map<String, dynamic> input,
  ) async {
    // The real tool's input/output shape wasn't spiked live (to avoid extra
    // billed API calls) — handle both a single question/options pair and a
    // questions-array shape defensively; only the first question is used,
    // since `TaskQuestion` models one question at a time. The resolved
    // answer is folded back into `updatedInput` under the same shape it
    // arrived in, since planning must see what the developer actually
    // picked rather than the original, unanswered input (design doc §6.4).
    String question;
    List<String> options;
    final questions = input['questions'];
    final usesQuestionsArray = questions is List && questions.isNotEmpty;
    Map<String, dynamic>? firstQuestionMap;
    if (usesQuestionsArray) {
      final first = questions.first;
      firstQuestionMap = first is Map
          ? first.cast<String, dynamic>()
          : const {};
      question = firstQuestionMap['question']?.toString() ?? '';
      options = _asStringOptions(firstQuestionMap['options']);
    } else {
      question = input['question']?.toString() ?? '';
      options = _asStringOptions(input['options']);
    }

    final created = await createQuestion(taskId, question, options);
    final answered = await watchAnswer(created.id!).first;
    final answer = answered.answer ?? '';

    final updatedInput = Map<String, dynamic>.from(input);
    if (usesQuestionsArray) {
      final updatedQuestions = List<dynamic>.from(questions);
      updatedQuestions[0] = {...?firstQuestionMap, 'answer': answer};
      updatedInput['questions'] = updatedQuestions;
    } else {
      updatedInput['answer'] = answer;
    }

    return PermissionDecision.allow(updatedInput: updatedInput);
  }

  List<String> _asStringOptions(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (o) => o is Map
              ? (o['label']?.toString() ?? o.toString())
              : o.toString(),
        )
        .toList();
  }

  Future<PermissionDecision> _decideExitPlanMode(
    Map<String, dynamic> input,
  ) async {
    final plan = input['plan']?.toString() ?? '';
    await setPlanReady(taskId, plan);
    final decision = await watchPlanDecision(taskId).first;
    if (decision.status == TaskStatus.running) {
      return PermissionDecision.allow(updatedInput: input);
    }
    final feedback = await latestFeedback(taskId);
    return PermissionDecision.deny(feedback?.message ?? 'Plan needs revision.');
  }
}

/// Runs [tool] as a minimal stdio MCP server exposing one tool named
/// [toolName] (invoked by `claude` as `mcp__<serverName>__<toolName>`, see
/// `ClaudeCodeExecutor.runPlanning`'s `permissionPromptTool` argument).
///
/// Hand-rolls the MCP stdio wire protocol (newline-delimited JSON-RPC 2.0)
/// rather than depending on an external MCP package — the protocol surface
/// needed here (`initialize`, `notifications/initialized`, `tools/list`,
/// `tools/call`) was confirmed minimal and stable by a manual spike against
/// the real `claude` CLI. [input]/[output] are injectable for testing;
/// default to real stdin/stdout.
Future<void> runPermissionPromptToolServer(
  PermissionPromptTool tool, {
  required String toolName,
  required String serverName,
  Stream<List<int>>? input,
  void Function(String line)? output,
}) async {
  final write =
      output ??
      (line) {
        // ignore: avoid_print
        print(line);
      };
  void send(Map<String, dynamic> message) => write(jsonEncode(message));

  final lines = (input ?? io.stdin)
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  await for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final Map<String, dynamic> request;
    try {
      request = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    final method = request['method'] as String?;
    final id = request['id'];

    switch (method) {
      case 'initialize':
        send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'protocolVersion': '2024-11-05',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': serverName, 'version': '0.0.1'},
          },
        });
      case 'notifications/initialized':
        // No response expected for a notification.
        break;
      case 'tools/list':
        send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'tools': [
              {
                'name': toolName,
                'description': 'Approve or deny a pending tool call.',
                'inputSchema': {
                  'type': 'object',
                  'properties': {
                    'tool_name': {'type': 'string'},
                    'input': {'type': 'object'},
                  },
                  'required': ['tool_name', 'input'],
                },
              },
            ],
          },
        });
      case 'tools/call':
        final params =
            (request['params'] as Map?)?.cast<String, dynamic>() ?? const {};
        final arguments =
            (params['arguments'] as Map?)?.cast<String, dynamic>() ?? const {};
        final callToolName = arguments['tool_name']?.toString() ?? '';
        final callInput =
            (arguments['input'] as Map?)?.cast<String, dynamic>() ?? const {};
        PermissionDecision decision;
        try {
          decision = await tool.decide(callToolName, callInput);
        } catch (e) {
          // A transient failure in one of the injected callbacks (network
          // RPC/streaming to the server) must not take down the whole
          // subprocess — with --strict-mcp-config this is the only
          // permission tool `claude` has for the entire planning-phase
          // session, so an uncaught exception here would silently kill
          // plan-mode handling for the rest of that run.
          decision = PermissionDecision.deny(
            'permission-prompt-tool error: $e',
          );
        }
        send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'content': [
              {'type': 'text', 'text': jsonEncode(decision.toJson())},
            ],
          },
        });
      default:
        if (id != null) {
          send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32601, 'message': 'not implemented'},
          });
        }
    }
  }
}
