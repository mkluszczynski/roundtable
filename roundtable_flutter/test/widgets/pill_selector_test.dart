import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/pill_selector.dart';

void main() {
  testWidgets('tapping an option calls onChanged with that option', (
    tester,
  ) async {
    String? changedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: PillSelector<String>(
          options: const ['a', 'b', 'c'],
          labelBuilder: (o) => o,
          selected: 'a',
          onChanged: (o) => changedTo = o,
        ),
      ),
    );

    await tester.tap(find.text('b'));
    expect(changedTo, 'b');
  });

  testWidgets('a disabled option shows its hint and is unselectable', (
    tester,
  ) async {
    String? changedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: PillSelector<String>(
          options: const ['native', 'docker'],
          labelBuilder: (o) => o,
          selected: 'native',
          onChanged: (o) => changedTo = o,
          disabledOptions: const {'docker'},
          disabledHint: 'Coming soon',
        ),
      ),
    );

    expect(find.text('Coming soon'), findsOneWidget);

    await tester.tap(find.text('docker'), warnIfMissed: false);
    expect(changedTo, isNull);
  });
}
