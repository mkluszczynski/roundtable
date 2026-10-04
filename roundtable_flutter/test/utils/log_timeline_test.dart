import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/log_timeline.dart';

TaskLogEntry _s(
  String content,
  LogKind kind, {
  String run = 'r1',
  LogPhase phase = LogPhase.planning,
  String? tool,
  String? id,
}) => TaskLogEntry(
  taskId: 1,
  content: content,
  kind: kind,
  runId: run,
  phase: phase,
  toolName: tool,
  toolUseId: id,
);

TaskLogEntry _l(String content) => TaskLogEntry(taskId: 1, content: content);

void main() {
  test('structured entries group into runs, messages and activity', () {
    final runs = buildLogTimeline([
      _s('Ada started planning', LogKind.runStarted),
      _s('Read(/a)', LogKind.toolCall, tool: 'Read', id: 't1'),
      _s('Read(/b)', LogKind.toolCall, tool: 'Read', id: 't2'),
      _s('b contents', LogKind.toolResult, id: 't2'),
      _s('a contents', LogKind.toolResult, id: 't1'),
      _s('It is hardcoded.', LogKind.message),
      _s('Done in 3.0s', LogKind.runFinished),
      _s(
        'Leon started a code review',
        LogKind.runStarted,
        run: 'r2',
        phase: LogPhase.review,
      ),
    ]);

    expect(runs, hasLength(2));
    final first = runs.first;
    expect(first.title, 'Ada started planning');
    expect(first.finished?.content, 'Done in 3.0s');
    expect(first.stepCount, 2);
    final activity = first.blocks.first as ActivityBlock;
    expect(activity.summary, 'Read ×2');
    expect(activity.steps.first.result?.content, 'a contents');
    expect((first.blocks.last as MessageBlock).text, 'It is hardcoded.');
    expect(runs.last.isReview, isTrue);
  });

  test('legacy lines split runs after a finish and on [review]', () {
    final runs = buildLogTimeline([
      _l('Looking around.'),
      _l('🔧 Grep \'x\' in .'),
      _l('✓ found'),
      _l('✅ Done in 1.0s'),
      _l('Second attempt.'),
      _l('[review] Leon started a code review'),
      _l('[review] 🔧 Bash: git diff'),
      _l('[review] Looks fine.'),
    ]);

    expect(runs, hasLength(3));
    expect(runs[0].finished, isNotNull);
    expect((runs[0].blocks[1] as ActivityBlock).steps.single.toolName, 'Grep');
    expect((runs[1].blocks.single as MessageBlock).text, 'Second attempt.');
    expect(runs[2].isReview, isTrue);
    expect(runs[2].title, 'Leon started a code review');
    expect((runs[2].blocks.last as MessageBlock).text, 'Looks fine.');
  });

  test('consecutive messages merge into one block', () {
    final runs = buildLogTimeline([_l('One.'), _l('Two.')]);
    expect((runs.single.blocks.single as MessageBlock).text, 'One.\n\nTwo.');
  });
}
