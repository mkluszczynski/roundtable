import 'package:roundtable_agent_runner/src/role_prompts.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  test('uses the role prompt from the server with the agent name', () {
    final agent = Agent(
      machineId: 1,
      name: 'Ana',
      role: AgentRoleDefinition(
        name: 'reviewer',
        prompt: 'You are {name}, a strict reviewer. {name} never edits code.',
      ),
    );

    expect(
      buildRolePrompt(agent),
      'You are Ana, a strict reviewer. Ana never edits code.',
    );
  });

  test('falls back to a generalist prompt without a role', () {
    final agent = Agent(machineId: 1, name: 'Ana');

    expect(
      buildRolePrompt(agent),
      'You are Ana, a generalist engineer on this team.',
    );
  });
}
