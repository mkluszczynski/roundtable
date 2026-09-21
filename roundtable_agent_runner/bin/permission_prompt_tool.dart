import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';

/// Entrypoint for the `--permission-prompt-tool` MCP server (design doc
/// §6.4), spawned by the `claude` CLI itself per the `--mcp-config` JSON
/// `TaskDispatcher` writes for a planning-phase run. Reads `SERVER_URL` and
/// `ROUNDTABLE_TASK_ID` from the environment — set alongside the process by
/// `TaskDispatcher`, not passed as CLI args, since `--mcp-config` only
/// supports a static command/args/env per server.
Future<void> main() async {
  final serverUrl = Platform.environment['SERVER_URL'];
  final taskIdRaw = Platform.environment['ROUNDTABLE_TASK_ID'];
  if (serverUrl == null || serverUrl.isEmpty) {
    stderr.writeln('permission-prompt-tool: missing SERVER_URL');
    exit(1);
  }
  final taskId = int.tryParse(taskIdRaw ?? '');
  if (taskId == null) {
    stderr.writeln(
      'permission-prompt-tool: missing/invalid ROUNDTABLE_TASK_ID',
    );
    exit(1);
  }

  final client = Client(serverUrl.endsWith('/') ? serverUrl : '$serverUrl/');
  final tool = PermissionPromptTool(
    taskId: taskId,
    createQuestion: (taskId, question, options) =>
        client.task.createQuestion(taskId, question, options),
    watchAnswer: (questionId) => client.task.watchAnswer(questionId),
    setPlanReady: (taskId, plan) => client.task.setPlanReady(taskId, plan),
    watchPlanDecision: (taskId) => client.task.watchPlanDecision(taskId),
    latestFeedback: (taskId) => client.task.latestFeedback(taskId),
  );

  await runPermissionPromptToolServer(
    tool,
    toolName: 'approval_prompt',
    serverName: 'roundtable-permission',
  );
}
