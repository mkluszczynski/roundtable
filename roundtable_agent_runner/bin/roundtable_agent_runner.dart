import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';

Future<void> main() async {
  final AgentRunnerConfig config;
  try {
    config = AgentRunnerConfig.load();
  } on StateError catch (e) {
    stderr.writeln('agent-runner: ${e.message}');
    exit(1);
  }

  final service = AgentRunnerService(config);

  for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
    signal.watch().listen((_) {
      stdout.writeln('received ${signal.name}, shutting down');
      service.stop();
    });
  }

  await service.run();
  // The signal-watch subscriptions above keep the event loop alive even
  // after the heartbeat loop stops, so a graceful (exitCode: 0) shutdown
  // needs an explicit exit — otherwise systemd waits out the stop timeout
  // and SIGKILLs the process instead of seeing it exit on its own.
  exit(0);
}
