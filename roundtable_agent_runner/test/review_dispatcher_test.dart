import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  group('parseReviewOutput', () {
    test('parses the last fenced json block', () {
      final result = parseReviewOutput('''
I looked around.

```json
{"summary": "draft", "comments": []}
```

Final answer:

```json
{
  "summary": "Mostly fine.",
  "comments": [
    {"path": "lib/a.dart", "line": 3, "severity": "blocker", "body": "Crash on null"},
    {"path": "README.md", "line": null, "severity": "nit", "body": "Typo"}
  ]
}
```
''');

      expect(result, isNotNull);
      expect(result!.summary, 'Mostly fine.');
      expect(result.comments, hasLength(2));
      expect(result.comments[0].path, 'lib/a.dart');
      expect(result.comments[0].line, 3);
      expect(result.comments[0].severity, ReviewCommentSeverity.blocker);
      expect(result.comments[1].line, isNull);
      expect(result.comments[1].severity, ReviewCommentSeverity.nit);
    });

    test('accepts bare JSON', () {
      final result = parseReviewOutput('{"summary": "LGTM", "comments": []}');
      expect(result!.summary, 'LGTM');
      expect(result.comments, isEmpty);
    });

    test('defaults an unknown severity to issue and skips invalid items', () {
      final result = parseReviewOutput('''```json
{"summary": "s", "comments": [
  {"path": "a.dart", "line": 0, "severity": "critical", "body": "x"},
  {"line": 4, "body": "no path"},
  "not an object"
]}
```''');
      expect(result!.comments, hasLength(1));
      expect(result.comments.single.severity, ReviewCommentSeverity.issue);
      expect(result.comments.single.line, isNull);
    });

    test('returns null without valid JSON', () {
      expect(parseReviewOutput('No JSON here.'), isNull);
      expect(parseReviewOutput('```json\n{not json}\n```'), isNull);
      expect(parseReviewOutput('```json\n{"summary": 1}\n```'), isNull);
    });
  });

  test('buildReviewPrompt includes the task and the diff base', () {
    final prompt = buildReviewPrompt(
      rolePrompt: 'You are Ana.',
      taskPrompt: 'Add a login page',
      baseSha: 'abc123',
    );
    expect(prompt, contains('You are Ana.'));
    expect(prompt, contains('Add a login page'));
    expect(prompt, contains('git diff abc123...HEAD'));
    expect(prompt, contains('```json'));
  });
}
