import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  test('lists available and missing tools and the environment limits', () {
    final prompt = buildEnvironmentPrompt(
      machineName: 'vps-1',
      user: 'roundtable-agent',
      tools: [
        (name: 'git', version: 'git version 2.43.0'),
        (name: 'dart', version: null),
      ],
    );

    expect(prompt, contains('"vps-1"'));
    expect(prompt, contains('`roundtable-agent`'));
    expect(prompt, contains('- git: git version 2.43.0'));
    expect(prompt, contains('Not installed here: dart.'));
    expect(prompt, contains('No MCP servers'));
    expect(prompt, contains('"Not verified here"'));
  });

  test('a review prompt asks to report gaps in the review', () {
    final prompt = buildEnvironmentPrompt(
      machineName: 'vps-1',
      user: 'roundtable-agent',
      tools: const [],
      review: true,
    );
    expect(prompt, contains('(none detected)'));
    expect(prompt, contains('in your review'));
    expect(prompt, isNot(contains('pull request description')));
  });

  test('detectToolchain reports a missing tool as null', () async {
    final tools = await detectToolchain(
      tools: ['git', 'definitely-not-a-real-tool-xyz'],
    );
    expect(tools.last.version, isNull);
  });
}
