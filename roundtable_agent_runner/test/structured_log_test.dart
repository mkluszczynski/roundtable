import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  group('StreamJsonFormatter.feedEntries', () {
    late StreamJsonFormatter formatter;
    setUp(() => formatter = StreamJsonFormatter());

    test('a tool call carries its name, id and full input', () {
      formatter.feedEntries(
        '{"type":"stream_event","event":{"type":"content_block_start","index":0,'
        '"content_block":{"type":"tool_use","id":"tu_1","name":"Read"}}}',
      );
      formatter.feedEntries(
        '{"type":"stream_event","event":{"type":"content_block_delta","index":0,'
        '"delta":{"type":"input_json_delta","partial_json":"{\\"file_path\\":\\"/a.dart\\"}"}}}',
      );
      final items = formatter.feedEntries(
        '{"type":"stream_event","event":{"type":"content_block_stop","index":0}}',
      );

      final call = items.single;
      expect(call.kind, LogKind.toolCall);
      expect(call.content, 'Read(/a.dart)');
      expect(call.toolName, 'Read');
      expect(call.toolUseId, 'tu_1');
      expect(call.detail, contains('"file_path": "/a.dart"'));
    });

    test('a tool result is paired by id, keeps newlines in detail and '
        'drops internal metadata', () {
      final items = formatter.feedEntries(
        '{"type":"user","message":{"content":[{"type":"tool_result",'
        '"tool_use_id":"tu_1","content":"line 1\\nline 2 (This tool result is '
        'internal metadata — never quote it.) end"}]}}',
      );

      final result = items.single;
      expect(result.kind, LogKind.toolResult);
      expect(result.toolUseId, 'tu_1');
      expect(result.detail, 'line 1\nline 2 end');
      expect(result.content, 'line 1 line 2 end');
    });

    test('a background subagent receipt becomes a short note', () {
      final items = formatter.feedEntries(
        '{"type":"user","message":{"content":[{"type":"tool_result",'
        '"tool_use_id":"tu_2","content":"Async agent launched successfully. '
        'agentId: abc123"}]}}',
      );
      expect(items.single.content, 'Subagent started in the background.');
    });

    test('the final result is a runFinished item', () {
      final items = formatter.feedEntries(
        '{"type":"result","subtype":"success","duration_ms":1500}',
      );
      expect(items.single.kind, LogKind.runFinished);
      expect(items.single.content, 'Done in 1.5s');
      expect(items.single.line, '✅ Done in 1.5s');
    });
  });

  test('stripReviewJson drops the trailing verdict block only', () {
    const message =
        'Looks good overall.\n\n```json\n{"summary": "ok", "comments": []}\n```';
    expect(stripReviewJson(message), 'Looks good overall.');
    expect(stripReviewJson('No JSON here.'), 'No JSON here.');
  });

  test('logEntryFor fills the run, phase and review', () {
    final entry = logEntryFor(
      const LogItem(kind: LogKind.message, content: 'Hi'),
      taskId: 7,
      runId: 'review-3-1',
      phase: LogPhase.review,
      reviewId: 3,
    );
    expect(entry.taskId, 7);
    expect(entry.kind, LogKind.message);
    expect(entry.runId, 'review-3-1');
    expect(entry.phase, LogPhase.review);
    expect(entry.reviewId, 3);
  });
}
