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
    expect(prompt, contains('Do NOT commit, push'));
    expect(prompt, contains('never blocks the work itself'));
    expect(prompt, contains('final message becomes the pull request'));
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
    expect(prompt, isNot(contains('Do NOT commit')));
  });

  test('detectToolchain reports a missing tool as null', () async {
    final tools = await detectToolchain(
      tools: ['git', 'definitely-not-a-real-tool-xyz'],
    );
    expect(tools.last.version, isNull);
  });

  test('the PR body quotes the prompt and adds the agent summary', () {
    final body = pullRequestBody(
      agentName: 'Ada',
      prompt: 'Update models\nto the latest',
      summary: 'Updated the list.\n\nNot verified here: dart analyze',
    );
    expect(body, contains('> Update models\n> to the latest'));
    expect(body, contains("## Agent's summary\nUpdated the list."));
    expect(
      pullRequestBody(agentName: 'Ada', prompt: 'x', summary: '  '),
      isNot(contains('summary')),
    );
  });

  test('the task title prompt names the MCP tool to call', () {
    expect(
      taskTitlePrompt(),
      contains('`mcp__roundtable-permission__set_task_title`'),
    );
  });

  group('parseOsRelease', () {
    test('reads NAME and VERSION_ID', () {
      expect(
        parseOsRelease('''
PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
ID=ubuntu
'''),
        'Ubuntu 24.04',
      );
      expect(
        parseOsRelease(
          'PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"\n'
          'NAME="Debian GNU/Linux"\nVERSION_ID="12"\n',
        ),
        'Debian GNU/Linux 12',
      );
    });

    test('falls back to PRETTY_NAME, then NAME, without a VERSION_ID', () {
      expect(
        parseOsRelease('NAME="Arch"\nPRETTY_NAME="Arch Linux"\nID=arch\n'),
        'Arch Linux',
      );
      expect(parseOsRelease("NAME='Gentoo'\n"), 'Gentoo');
    });

    test('is null without any name', () {
      expect(parseOsRelease(''), isNull);
      expect(parseOsRelease('# NAME=x\nID=x\n'), isNull);
    });
  });

  test('detectOsVersion returns a non-empty description', () async {
    expect(await detectOsVersion(), isNotEmpty);
  });
}
