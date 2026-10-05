import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/tool_list_editor.dart';

/// Hosts the controlled editor with real state, recording each change.
class _Host extends StatefulWidget {
  const _Host({required this.initial, this.onDetect, required this.changes});

  final List<ProjectTool> initial;
  final Future<List<ProjectTool>> Function()? onDetect;
  final List<List<ProjectTool>> changes;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late var _tools = widget.initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: ToolListEditor(
        tools: _tools,
        onDetect: widget.onDetect,
        onChanged: (tools) {
          widget.changes.add(tools);
          setState(() => _tools = tools);
        },
      ),
    ),
  );
}

String _names(List<ProjectTool> tools) =>
    tools.map((t) => '${t.name}@${t.version}').join(', ');

void main() {
  testWidgets('adding from the catalog appends the tool at latest', (
    tester,
  ) async {
    final changes = <List<ProjectTool>>[];
    await tester.pumpWidget(_Host(initial: const [], changes: changes));
    expect(find.textContaining('No tools'), findsOneWidget);

    await tester.tap(find.text('Add tool'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Node.js'));
    await tester.pumpAndSettle();

    expect(_names(changes.last), 'node@latest');
    expect(find.text('Node.js'), findsOneWidget);
  });

  testWidgets('a version is committed when submitted, and removing works', (
    tester,
  ) async {
    final changes = <List<ProjectTool>>[];
    await tester.pumpWidget(
      _Host(
        initial: [ProjectTool(name: 'flutter', version: 'latest')],
        changes: changes,
      ),
    );

    await tester.enterText(find.byType(TextField), '3.24.0');
    expect(changes, isEmpty, reason: 'not saved on each keystroke');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_names(changes.last), 'flutter@3.24.0');

    await tester.tap(find.byTooltip('Remove flutter'));
    await tester.pump();
    expect(changes.last, isEmpty);
  });

  testWidgets('detection adds only tools that are not listed yet', (
    tester,
  ) async {
    final changes = <List<ProjectTool>>[];
    await tester.pumpWidget(
      _Host(
        initial: [ProjectTool(name: 'node', version: '22')],
        changes: changes,
        onDetect: () async => [
          ProjectTool(name: 'node', version: 'lts'),
          ProjectTool(name: 'flutter', version: 'latest'),
        ],
      ),
    );

    await tester.tap(find.text('Detect from repo'));
    await tester.pumpAndSettle();

    expect(_names(changes.last), 'node@22, flutter@latest');
    expect(find.textContaining('Added flutter'), findsOneWidget);
  });

  testWidgets('a failed detection says why', (tester) async {
    await tester.pumpWidget(
      _Host(
        initial: const [],
        changes: [],
        onDetect: () async => throw Exception('404'),
      ),
    );

    await tester.tap(find.text('Detect from repo'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't read the repo"), findsOneWidget);
  });
}
