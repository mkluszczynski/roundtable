import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  group('StreamJsonFormatter', () {
    late StreamJsonFormatter formatter;

    setUp(() => formatter = StreamJsonFormatter());

    test('system/init is dropped', () {
      const line =
          '{"type":"system","subtype":"init","cwd":"/tmp","session_id":"abc"}';
      expect(formatter.feed(line), isEmpty);
    });

    test('a text turn split across several deltas assembles into one line', () {
      formatter.feed(
        '{"type":"stream_event","event":{"type":"message_start",'
        '"message":{"model":"claude-sonnet-5","content":[],"role":"assistant"}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_start",'
        '"index":0,"content_block":{"type":"text","text":""}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":0,"delta":{"type":"text_delta","text":"Hello, "}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":0,"delta":{"type":"text_delta","text":"world."}}}',
      );
      final lines = formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_stop","index":0}}',
      );

      expect(lines, ['Hello, world.']);
    });

    test('a thinking block is emitted prefixed, ignoring signature deltas', () {
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_start",'
        '"index":0,"content_block":{"type":"thinking"}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":0,"delta":{"type":"thinking_delta","thinking":"Let me check."}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":0,"delta":{"type":"signature_delta","signature":"abc123"}}}',
      );
      final lines = formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_stop","index":0}}',
      );

      expect(lines, ['🤔 Let me check.']);
    });

    test('a tool_use with input split across several input_json_delta chunks '
        'assembles into one correctly-summarized line', () {
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_start",'
        '"index":1,"content_block":{"type":"tool_use",'
        '"id":"toolu_01csCL7mNcRm2xRNhuQBthEf","name":"Agent","input":{}},'
        '"caller":{"type":"direct"}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":1,"delta":{"type":"input_json_delta","partial_json":""}}}',
      );
      // Real Claude Code splits `partial_json` mid-token across many
      // deltas; here it arrives in three chunks that only form valid JSON
      // once fully concatenated, exercising the buffering.
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":1,"delta":{"type":"input_json_delta",'
        r'"partial_json":"{\"subagent_type\":\"Explore\","}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":1,"delta":{"type":"input_json_delta",'
        r'"partial_json":"\"description\":\"Find machine detail and '
        r'dashboard list code\","}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":1,"delta":{"type":"input_json_delta",'
        r'"partial_json":"\"prompt\":\"This is a bug\"}"}}}',
      );

      final lines = formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_stop","index":1}}',
      );

      expect(lines, [
        '🔧 Explore: Find machine detail and dashboard list code',
      ]);
    });

    test('a malformed line is ignored without throwing', () {
      expect(formatter.feed('not json at all'), isEmpty);
      expect(formatter.feed('{"type":"stream_event"'), isEmpty);
    });

    test('an unknown tool name falls back to name + truncated input', () {
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_start",'
        '"index":0,"content_block":{"type":"tool_use","name":"WebSearch"}}}',
      );
      formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_delta",'
        '"index":0,"delta":{"type":"input_json_delta",'
        r'"partial_json":"{\"query\":\"roundtable hackathon\"}"}}}',
      );
      final lines = formatter.feed(
        '{"type":"stream_event","event":{"type":"content_block_stop","index":0}}',
      );

      expect(lines, ['🔧 WebSearch({"query":"roundtable hackathon"})']);
    });

    test('a successful tool_result is emitted with a checkmark', () {
      final lines = formatter.feed(
        '{"type":"user","message":{"role":"user","content":'
        '[{"type":"tool_result","tool_use_id":"toolu_1",'
        '"content":[{"type":"text","text":"file written"}]}]}}',
      );
      expect(lines, ['✓ file written']);
    });

    test('a failing tool_result is emitted with an X mark', () {
      final lines = formatter.feed(
        '{"type":"user","message":{"role":"user","content":'
        '[{"type":"tool_result","tool_use_id":"toolu_1","is_error":true,'
        '"content":"No such file or directory"}]}}',
      );
      expect(lines, ['✗ No such file or directory']);
    });

    test('a complete non-streamed assistant message is dropped', () {
      final lines = formatter.feed(
        '{"type":"assistant","message":{"role":"assistant","content":'
        '[{"type":"text","text":"Hello"}]}}',
      );
      expect(lines, isEmpty);
    });

    test('a successful result reports completion with duration', () {
      final lines = formatter.feed(
        '{"type":"result","subtype":"success","session_id":"sess-1",'
        '"duration_ms":42500}',
      );
      expect(lines, ['✅ Done in 42.5s']);
    });

    test('a result with no duration still reports completion', () {
      final lines = formatter.feed(
        '{"type":"result","subtype":"success","session_id":"sess-1"}',
      );
      expect(lines, ['✅ Done']);
    });

    test('a failing result reports the error', () {
      final lines = formatter.feed(
        '{"type":"result","subtype":"error_max_turns","is_error":true,'
        '"result":"Reached max turns"}',
      );
      expect(lines, ['❌ Failed: Reached max turns']);
    });
  });
}
