import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given AgentRole endpoint', (sessionBuilder, endpoints) {
    Future<AgentRoleDefinition> createRole(String name) =>
        endpoints.agentRole.create(
          sessionBuilder,
          AgentRoleDefinition(name: name, prompt: 'You are {name}, $name.'),
        );

    test('when creating a role then it is listed, trimmed', () async {
      await endpoints.agentRole.create(
        sessionBuilder,
        AgentRoleDefinition(
          name: '  reviewer ',
          description: '  ',
          prompt: ' You review code. ',
        ),
      );

      final roles = await endpoints.agentRole.list(sessionBuilder);

      expect(roles.map((r) => r.name), contains('reviewer'));
      final role = roles.firstWhere((r) => r.name == 'reviewer');
      expect(role.prompt, 'You review code.');
      expect(role.description, isNull);
    });

    test('when a name is taken (any case) then creating fails', () async {
      await createRole('backend');

      await expectLater(
        createRole('Backend'),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test('when editing a role then its prompt changes', () async {
      final role = await createRole('backend');

      final updated = await endpoints.agentRole.update(
        sessionBuilder,
        role.copyWith(prompt: 'You are {name}, the API person.'),
      );

      expect(updated.prompt, 'You are {name}, the API person.');
    });

    test('when an agent uses the role then deleting is blocked', () async {
      final role = await createRole('backend');
      final machine = await Machine.db.insertRow(
        sessionBuilder.build(),
        Machine(name: 'VPS'),
      );
      await endpoints.agent.create(
        sessionBuilder,
        'Ana',
        machine.id!,
        roleId: role.id,
      );

      await expectLater(
        endpoints.agentRole.delete(sessionBuilder, role.id!),
        throwsA(
          isA<DeletionBlockedException>().having(
            (e) => e.reason,
            'reason',
            DeletionBlockReason.roleInUse,
          ),
        ),
      );
    });

    test('when no agent uses the role then it is deleted', () async {
      final role = await createRole('backend');

      await endpoints.agentRole.delete(sessionBuilder, role.id!);

      final roles = await endpoints.agentRole.list(sessionBuilder);
      expect(roles.map((r) => r.id), isNot(contains(role.id)));
    });
  });
}
