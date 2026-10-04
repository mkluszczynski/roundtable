import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/question_context.dart';

TaskLogEntry _log(String content) => TaskLogEntry(taskId: 1, content: content);

void main() {
  test('takes the agent message right before the question', () {
    final context = questionContext([
      _log('Earlier remark.'),
      _log('🔧 Read(file.dart)'),
      _log('✓ 1 import …'),
      _log('The list is hardcoded in add_agent_dialog.dart.'),
      _log('Fetching it needs an API key.'),
      _log('🔧 AskUserQuestion({"questions": …})'),
    ]);
    expect(
      context,
      'The list is hardcoded in add_agent_dialog.dart.\n\n'
      'Fetching it needs an API key.',
    );
  });

  test('uses the latest question when several were asked', () {
    final context = questionContext([
      _log('First context.'),
      _log('🔧 AskUserQuestion({…})'),
      _log('✓ answered'),
      _log('Second context.'),
      _log('🔧 AskUserQuestion({…})'),
    ]);
    expect(context, 'Second context.');
  });

  test('is null when the agent said nothing before asking', () {
    expect(
      questionContext([_log('✓ done'), _log('🔧 AskUserQuestion({…})')]),
      isNull,
    );
  });
}
