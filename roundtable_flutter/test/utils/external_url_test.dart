import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/utils/external_url.dart';

void main() {
  test('https links open', () {
    expect(
      safeExternalUri('https://github.com/acme/app/pull/5').toString(),
      'https://github.com/acme/app/pull/5',
    );
  });

  test('anything else is refused', () {
    for (final url in [
      'file:///etc/passwd',
      'javascript:alert(1)',
      'http://github.com/acme/app',
      'vscode://file/home/me',
      'not a url',
      'https://',
      '',
    ]) {
      expect(safeExternalUri(url), isNull, reason: url);
    }
  });
}
