import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  group('AgentRunnerConfig.load', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('agent_runner_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    String writeConfig(String content) {
      final file = File('${tempDir.path}/config.env');
      file.writeAsStringSync(content);
      return file.path;
    }

    test('parses required and optional keys', () {
      final path = writeConfig('''
# comment, should be ignored
REGISTRATION_TOKEN=abc123
SERVER_URL=http://localhost:8080
CLAUDE_CODE_OAUTH_TOKEN=claude-token
''');

      final config = AgentRunnerConfig.load(path: path);

      expect(config.registrationToken, 'abc123');
      expect(config.serverUrl, 'http://localhost:8080');
      expect(config.claudeCodeOauthToken, 'claude-token');
    });

    test('claudeCodeOauthToken is optional', () {
      final path = writeConfig('''
REGISTRATION_TOKEN=abc123
SERVER_URL=http://localhost:8080
''');

      final config = AgentRunnerConfig.load(path: path);

      expect(config.claudeCodeOauthToken, isNull);
    });

    test('throws when the file is missing', () {
      expect(
        () => AgentRunnerConfig.load(path: "${tempDir.path}/missing.env"),
        throwsStateError,
      );
    });

    test('throws when REGISTRATION_TOKEN is missing', () {
      final path = writeConfig('SERVER_URL=http://localhost:8080\n');

      expect(() => AgentRunnerConfig.load(path: path), throwsStateError);
    });

    test('throws when SERVER_URL is missing', () {
      final path = writeConfig('REGISTRATION_TOKEN=abc123\n');

      expect(() => AgentRunnerConfig.load(path: path), throwsStateError);
    });
  });
}
