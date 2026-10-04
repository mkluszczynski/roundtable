import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/nav_rail.dart';

const _items = [
  NavRailItem(
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard,
    label: 'Dashboard',
  ),
  NavRailItem(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: 'Projects',
  ),
];

void main() {
  testWidgets('renders items, badges and footer; taps select', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppNavRail(
            items: _items,
            selectedIndex: 0,
            onSelected: selected.add,
            badges: const {0: Text('3')},
            footer: const Text('Live updates on'),
          ),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Live updates on'), findsOneWidget);
    expect(find.byIcon(Icons.space_dashboard), findsOneWidget);

    await tester.tap(find.text('Projects'));
    expect(selected, [1]);
  });
}
