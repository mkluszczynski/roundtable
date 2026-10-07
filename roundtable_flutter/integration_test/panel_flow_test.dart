// E2E UI tests (docs/DEVELOPMENT.md "E2E tests"): the panel clicked through
// against the real server and runner, a fake GitHub and a fake claude.
// Run on the Linux desktop: `flutter test integration_test -d linux`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:roundtable_flutter/client.dart';
import 'package:roundtable_flutter/main.dart';
import 'package:roundtable_flutter/widgets/create_task_dialog.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late E2EHarness e2e;

  setUpAll(() async {
    e2e = await E2EHarness.start(
      scenario: {
        'title': 'Add a greeting',
        'plan': '1. Create greeting.txt with a friendly hello.',
        'runs': [
          {
            'files': {'greeting.txt': 'Hello, world!\n'},
            'result': 'Created greeting.txt.',
          },
        ],
      },
    );
    await e2e.seed();
    await initializeClient(overrideUrl: e2e.client.host);
  });

  tearDownAll(() => e2e.stop());

  testWidgets('create a task, approve its plan and merge it from the panel', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Dashboard → New task.
    await tester.tapWhenShown(find.text('New task'));
    await tester.enterText(
      (await tester.shown(find.byType(TextField))).first,
      'Add a greeting file',
    );
    Finder inDialog(Finder finder) =>
        find.descendant(of: find.byType(CreateTaskDialog), matching: finder);
    await tester.tapWhenShown(inDialog(find.text('Demo')));
    await tester.tapWhenShown(inDialog(find.text('Ana')));
    await tester.tapWhenShown(inDialog(find.text('Create')));

    // The agent plans; open the task once its card shows the plan's title.
    await tester.tapWhenShown(
      find.text('Add a greeting'),
      timeout: const Duration(seconds: 60),
    );
    await tester.shown(find.textContaining('greeting.txt'));
    await tester.tapWhenShown(find.text('Approve & run'));

    // It runs and opens a PR; merge it.
    await tester.tapWhenShown(
      find.text('Accept & merge'),
      timeout: const Duration(seconds: 90),
    );
    await tester.tapWhenShown(find.text('Accept & merge').last);

    // The stack is fresh, so this is task 1.
    final task = await e2e.waitForStatus(1, TaskStatus.done);
    expect(task.title, 'Add a greeting');
    expect(
      await e2e.github.fileOn('acme', 'demo', 'main', 'greeting.txt'),
      'Hello, world!\n',
    );
  });
}

extension on WidgetTester {
  /// Pumps frames until [finder] matches (the panel's pulsing status dots
  /// never let `pumpAndSettle` settle), failing after [timeout].
  Future<Finder> shown(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        throw TestFailure('Timed out waiting for $finder');
      }
      await pump(const Duration(milliseconds: 200));
    }
    return finder;
  }

  Future<void> tapWhenShown(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await shown(finder, timeout: timeout);
    // A button shows disabled until its data loads (e.g. "New task" before
    // the projects arrive): wait until it's enabled.
    final button = find.ancestor(
      of: finder.first,
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    await shown(
      find.byWidgetPredicate(
        (w) =>
            w is ButtonStyleButton &&
            w.enabled &&
            button.evaluate().any((e) => e.widget == w),
      ),
      timeout: timeout,
    ).catchError((Object _) => button, test: (_) => button.evaluate().isEmpty);
    await ensureVisible(finder.first);
    await tap(finder.first);
    await pump(const Duration(milliseconds: 300));
  }
}
