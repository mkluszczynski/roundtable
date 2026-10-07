import 'dart:io';

import 'package:roundtable_agent_runner/src/claude_token_store.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('claude-token'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('uses the install token until one is set from the panel', () async {
    final path = '${dir.path}/sub/claude-oauth-token';
    final store = ClaudeTokenStore(path, installToken: 'install');
    expect(store.token, 'install');
    expect(store.source, ClaudeAuthSource.install);

    await store.save('panel');

    expect(store.token, 'panel');
    expect(store.source, ClaudeAuthSource.panel);
    expect(File('$path.tmp').existsSync(), isFalse);
    expect(File(path).readAsStringSync(), 'panel');
    expect(File(path).statSync().modeString(), 'rw-------');
  });

  test('a token set from the panel survives a restart', () async {
    final path = '${dir.path}/claude-oauth-token';
    await ClaudeTokenStore(path).save('panel');

    expect(ClaudeTokenStore(path, installToken: 'install').token, 'panel');
  });

  test('without a token, claude login credentials or nothing', () {
    final login = File('${dir.path}/.credentials.json');
    final store = ClaudeTokenStore(
      '${dir.path}/missing',
      loginCredentialsPath: login.path,
    );
    expect(store.token, isNull);
    expect(store.source, ClaudeAuthSource.none);

    login.writeAsStringSync('{}');

    expect(store.source, ClaudeAuthSource.login);
  });
}
