import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/follow_up_prompt.dart';

void main() {
  test('leaves room for the instruction and quotes the previous task', () {
    final prompt = followUpPrompt(
      Task(
        id: 35,
        projectId: 1,
        prompt: 'Analyze CI checks\nand propose a design',
        status: TaskStatus.done,
        resultSummary: '# Plan\nPoll GitHub every 30 s.',
      ),
    );

    expect(prompt, startsWith('\n\n---\nContext: follow-up to task #35.'));
    expect(prompt, contains('> Analyze CI checks\n> and propose a design'));
    expect(prompt, contains("The agent's final reply:\n# Plan"));
    expect(prompt, isNot(contains('pull request')));
  });

  test('mentions the PR when the task had one', () {
    final prompt = followUpPrompt(
      Task(
        id: 2,
        projectId: 1,
        prompt: 'Fix it',
        status: TaskStatus.done,
        prUrl: 'https://github.com/o/r/pull/9',
      ),
    );
    expect(prompt, contains('Its pull request: https://github.com/o/r/pull/9'));
    expect(prompt, isNot(contains('final reply')));
  });
}
