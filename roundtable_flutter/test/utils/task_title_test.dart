import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/task_title.dart';

void main() {
  Task task({String? title, String prompt = 'Fix the login bug'}) => Task(
    id: 1,
    projectId: 1,
    prompt: prompt,
    title: title,
    status: TaskStatus.queued,
  );

  test('uses the title when there is one', () {
    expect(taskDisplayTitle(task(title: 'Login fix')), 'Login fix');
  });

  test('falls back to the first non-blank line of the prompt', () {
    expect(
      taskDisplayTitle(task(prompt: '\n  Fix the login bug  \nDetails')),
      'Fix the login bug',
    );
  });

  test('a blank title counts as none', () {
    expect(taskDisplayTitle(task(title: '  ')), 'Fix the login bug');
  });
}
