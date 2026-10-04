import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  test('lists every attached image after the prompt', () {
    final prompt = attachedImagesPrompt('Fix the header', [
      '/tmp/x/1-a.png',
      '/tmp/x/2-b.png',
    ]);

    expect(prompt, startsWith('Fix the header\n\n'));
    expect(prompt, contains('2 image(s)'));
    expect(prompt, contains('Read tool'));
    expect(prompt, contains('- /tmp/x/1-a.png\n- /tmp/x/2-b.png'));
  });
}
