import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/utils/code_language.dart';

void main() {
  test('maps known extensions to a highlight language id', () {
    expect(languageForFilename('lib/main.dart'), 'dart');
    expect(languageForFilename('app/page.tsx'), 'typescript');
    expect(languageForFilename('scripts/deploy.sh'), 'bash');
    expect(languageForFilename('config.YAML'), 'yaml');
  });

  test('recognizes extensionless conventional filenames', () {
    expect(languageForFilename('Dockerfile'), 'dockerfile');
    expect(languageForFilename('path/to/Makefile'), 'makefile');
  });

  test('returns null for unknown or missing extensions', () {
    expect(languageForFilename('README'), isNull);
    expect(languageForFilename('.gitignore'), isNull);
    expect(languageForFilename('binaryfile.'), isNull);
  });
}
