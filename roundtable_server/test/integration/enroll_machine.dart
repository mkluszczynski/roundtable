import 'package:roundtable_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Adds a machine the way the panel and install-agent.sh do: an install
/// command, redeemed by the script (docs/FLOWS.md §1).
Future<({Machine machine, String token})> enrollMachine(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
  String name,
) async {
  final command = await endpoints.machine.createEnrollment(
    sessionBuilder,
    name: name,
  );
  final token = await endpoints.machine.enroll(
    sessionBuilder,
    command.enrollmentToken,
    'host',
  );
  final machine = await endpoints.machine.enrolledMachine(
    sessionBuilder,
    command.enrollmentId,
  );
  return (machine: machine!, token: token);
}
