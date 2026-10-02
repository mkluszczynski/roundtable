import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/runner_update_banner.dart';

void main() {
  group('runnerUpdateStatus', () {
    test('is upToDate when versions match or latest is unknown', () {
      expect(
        runnerUpdateStatus(
          installedVersion: 'a',
          latestVersion: 'a',
          updateRequestedAt: null,
        ),
        RunnerUpdateStatus.upToDate,
      );
      expect(
        runnerUpdateStatus(
          installedVersion: 'a',
          latestVersion: null,
          updateRequestedAt: null,
        ),
        RunnerUpdateStatus.upToDate,
      );
    });

    test('distinguishes available, updating and unsupported', () {
      expect(
        runnerUpdateStatus(
          installedVersion: 'a',
          latestVersion: 'b',
          updateRequestedAt: null,
        ),
        RunnerUpdateStatus.available,
      );
      expect(
        runnerUpdateStatus(
          installedVersion: 'a',
          latestVersion: 'b',
          updateRequestedAt: DateTime.now(),
        ),
        RunnerUpdateStatus.updating,
      );
      expect(
        runnerUpdateStatus(
          installedVersion: null,
          latestVersion: 'b',
          updateRequestedAt: null,
        ),
        RunnerUpdateStatus.unsupported,
      );
    });
  });

  testWidgets('Update button calls onUpdate when an update is available', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunnerUpdateBanner(
            status: RunnerUpdateStatus.available,
            onUpdate: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Agent runner update available'), findsOneWidget);
    await tester.tap(find.text('Update'));
    expect(tapped, isTrue);
  });

  testWidgets('shows no Update button while updating', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunnerUpdateBanner(
            status: RunnerUpdateStatus.updating,
            onUpdate: () {},
          ),
        ),
      ),
    );

    expect(find.text('Updating agent runner…'), findsOneWidget);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('renders nothing when up to date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunnerUpdateBanner(
            status: RunnerUpdateStatus.upToDate,
            onUpdate: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Text), findsNothing);
  });
}
