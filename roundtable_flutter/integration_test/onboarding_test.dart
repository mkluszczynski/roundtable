// E2E UI test of a first run (docs/DEVELOPMENT.md "E2E tests"): an empty
// panel → register a machine and start its runner → add an agent → connect
// a project, detecting its toolchains from the repo.
// Run on the Linux desktop: `flutter test integration_test -d linux`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:roundtable_flutter/client.dart';
import 'package:roundtable_flutter/main.dart';
import 'package:roundtable_flutter/widgets/add_agent_dialog.dart';
import 'package:roundtable_flutter/widgets/add_machine_dialog.dart';
import 'package:roundtable_flutter/widgets/add_project_dialog.dart';
import 'package:roundtable_flutter/widgets/code_block.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late E2EHarness e2e;

  setUpAll(() async {
    e2e = await E2EHarness.start(
      scenario: const {},
      withMachine: false,
      files: {
        'README.md': '# Demo\n',
        'pubspec.yaml': 'name: demo\nenvironment:\n  sdk: ^3.5.0\n',
      },
    );
    await initializeClient(overrideUrl: e2e.client.host);
  });

  tearDownAll(() => e2e.stop());

  testWidgets('from an empty panel to a machine, an agent and a project', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // 1. Register a machine; "install" its runner with the shown token.
    await tester.tapWhenShown(find.text('Add machine'));
    Finder inMachineDialog(Finder f) =>
        find.descendant(of: find.byType(AddMachineDialog), matching: f);
    await tester.enterText(
      inMachineDialog(find.widgetWithText(TextField, 'Name')),
      'Laptop',
    );
    await tester.enterText(
      inMachineDialog(
        find.widgetWithText(TextField, 'Claude Code OAuth token'),
      ),
      'fake-claude-token',
    );
    await tester.tapWhenShown(inMachineDialog(find.text('Register')));
    await tester.shown(find.text('Machine registered'));
    final command = tester.widget<CodeBlock>(find.byType(CodeBlock)).code;
    final token = RegExp(r'--token (\S+)').firstMatch(command)!.group(1)!;
    await tester.tapWhenShown(find.text('Done'));
    await tester.gone(find.byType(AddMachineDialog));
    final machine = await e2e.startRunner(token);
    expect(machine.name, 'Laptop');

    // 2. Add an agent on it.
    await tester.tapWhenShown(
      find.text('Add agent'),
      timeout: const Duration(seconds: 60),
    );
    Finder inAgentDialog(Finder f) =>
        find.descendant(of: find.byType(AddAgentDialog), matching: f);
    await tester.enterText(
      await tester.shown(inAgentDialog(find.widgetWithText(TextField, 'Name'))),
      'Ana',
    );
    await tester.tapWhenShown(
      inAgentDialog(find.widgetWithText(FilledButton, 'Add agent')),
    );
    await tester.gone(find.byType(AddAgentDialog));

    // 3. Connect the project; its toolchains come from the repo.
    await tester.tapWhenShown(
      find.text('Add project'),
      timeout: const Duration(seconds: 60),
    );
    Finder inProjectDialog(Finder f) =>
        find.descendant(of: find.byType(AddProjectDialog), matching: f);
    await tester.enterText(
      inProjectDialog(find.widgetWithText(TextField, 'Name')),
      'Demo',
    );
    await tester.enterText(
      inProjectDialog(find.widgetWithText(TextField, 'Repository URL')),
      e2e.github.repoUrl('acme', 'demo'),
    );
    await tester.enterText(
      inProjectDialog(
        find.widgetWithText(TextField, 'Repo access token (optional)'),
      ),
      'fake-token',
    );
    await tester.tapWhenShown(inProjectDialog(find.text('Detect from repo')));
    await tester.shown(inProjectDialog(find.textContaining('Added dart')));
    await tester.tapWhenShown(
      inProjectDialog(find.widgetWithText(FilledButton, 'Add project')),
    );
    await tester.gone(find.byType(AddProjectDialog));

    // The panel is ready for work.
    await tester.tapWhenShown(find.text('New task'));
    final projects = await e2e.client.project.list();
    expect(projects.single.name, 'Demo');
    expect(projects.single.tools!.map((t) => t.name), contains('dart'));
    final agents = await e2e.client.agent.list();
    expect(agents.single.name, 'Ana');
    expect(agents.single.machineId, machine.id);
  });
}
