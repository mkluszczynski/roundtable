import 'dart:convert';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  group('GitRemote.parse', () {
    test('moves the token from the URL into an Authorization header', () {
      final remote = GitRemote.parse(
        'https://x-access-token:ghp_secret@github.com/acme/app.git',
      );
      expect(remote.url, 'https://github.com/acme/app.git');
      expect(
        remote.authHeader,
        'Authorization: Basic '
        '${base64Encode(utf8.encode('x-access-token:ghp_secret'))}',
      );
    });

    test('leaves a URL without credentials alone', () {
      final remote = GitRemote.parse('https://github.com/acme/app.git');
      expect(remote.url, 'https://github.com/acme/app.git');
      expect(remote.authHeader, isNull);
    });
  });

  test('redactCredentials hides the userinfo of URLs in git output', () {
    expect(
      redactCredentials(
        "fatal: unable to access 'https://x-access-token:ghp_secret@github.com/a/b.git/'",
      ),
      "fatal: unable to access 'https://***@github.com/a/b.git/'",
    );
  });

  group('safeFileName', () {
    test('keeps a plain name', () {
      expect(safeFileName('screen-1.png'), 'screen-1.png');
    });

    test("can't climb out of the attachments dir", () {
      expect(safeFileName('../../.bashrc'), '_bashrc');
      expect(safeFileName(r'..\..\evil.png'), 'evil.png');
      expect(safeFileName('..'), '_');
      expect(safeFileName(''), 'image');
    });

    test('replaces unusual characters', () {
      expect(safeFileName('my shot (1).png'), 'my_shot__1_.png');
    });
  });
}
