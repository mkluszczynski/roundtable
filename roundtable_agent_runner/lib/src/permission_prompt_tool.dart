import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:roundtable_client/roundtable_client.dart';

/// The `{"behavior": ...}` JSON an MCP permission-prompt-tool call must
/// answer with (docs/FLOWS.md §4), confirmed against the real `claude` CLI by
/// a manual spike: `allow` must echo back a valid `updatedInput` (the tool's
/// original input, unless deliberately rewritten), `deny` carries the reason
/// Claude Code reports back to the model (folded into `ExitPlanMode`'s next
/// attempt as plan feedback).
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

/// Decision logic for the `--permission-prompt-tool` MCP tool (docs/FLOWS.md
/// §4), kept free of any MCP/stdio transport concerns so it's testable
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
    this.suggestTitle,
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

  /// Backs the `set_task_title` tool; without it the tool isn't offered.
  final Future<Task> Function(int taskId, String title)? suggestTitle;

  /// Handles a `set_task_title` call: the server keeps the title only while
  /// the task has none (`TaskEndpoint.suggestTitle`).
  Future<void> setTitle(String title) => suggestTitle!(taskId, title);

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
    // picked rather than the original, unanswered input (docs/FLOWS.md §4).
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
      // Claude Code reads answers from a top-level `answers` map keyed by
      // question text; without it the model is told the user didn't answer.
      final existing = input['answers'];
      updatedInput['answers'] = {
        if (existing is Map) ...existing.cast<String, dynamic>(),
        question: answer,
      };
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

/// Name of the MCP tool the agent calls to name its task, next to the
/// permission prompt tool (`mcp__roundtable-permission__set_task_title`).
const setTaskTitleToolName = 'set_task_title';

/// Runs [tool] as a minimal stdio MCP server exposing the permission prompt
/// tool named [toolName] (invoked by `claude` as
/// `mcp__<serverName>__<toolName>`, see `ClaudeCodeExecutor.runPlanning`'s
/// `permissionPromptTool` argument) and, when [PermissionPromptTool.suggestTitle]
/// is set, the agent-facing [setTaskTitleToolName] tool.
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
              if (tool.suggestTitle != null)
                {
                  'name': setTaskTitleToolName,
                  'description':
                      'Set a short, human-readable title for the task you '
                      'are working on, shown to the developer on the task '
                      'board. Call it once, at the start of your work.',
                  'inputSchema': {
                    'type': 'object',
                    'properties': {
                      'title': {
                        'type': 'string',
                        'description':
                            'At most ~60 characters, imperative mood, in the '
                            "language of the task's prompt.",
                      },
                    },
                    'required': ['title'],
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
        if (params['name'] == setTaskTitleToolName &&
            tool.suggestTitle != null) {
          var isError = false;
          String text;
          try {
            await tool.setTitle(arguments['title']?.toString() ?? '');
            text = 'Title set.';
          } catch (e) {
            // Naming the task is cosmetic — report it, never crash the
            // server the permission prompt tool also lives in.
            isError = true;
            text = 'Could not set the title: $e';
          }
          send({
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'content': [
                {'type': 'text', 'text': text},
              ],
              'isError': isError,
            },
          });
          break;
        }
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
