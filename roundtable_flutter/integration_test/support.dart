import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared helpers for the panel's E2E UI tests.
extension PanelTester on WidgetTester {
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

  /// Pumps frames until [finder] matches nothing (e.g. a dialog closed).
  Future<void> gone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        final texts = find
            .descendant(of: finder, matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .nonNulls
            .join(' | ');
        throw TestFailure(
          'Timed out waiting for $finder to go away. It shows: $texts',
        );
      }
      await pump(const Duration(milliseconds: 200));
    }
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
      // The finder may be the button itself.
      matchRoot: true,
    );
    final deadline = DateTime.now().add(timeout);
    while (button.evaluate().isNotEmpty &&
        !(button.evaluate().first.widget as ButtonStyleButton).enabled) {
      if (DateTime.now().isAfter(deadline)) {
        throw TestFailure('$finder never became enabled');
      }
      await pump(const Duration(milliseconds: 200));
    }
    await ensureVisible(finder.first);
    await tap(finder.first);
    await pump(const Duration(milliseconds: 300));
  }
}
