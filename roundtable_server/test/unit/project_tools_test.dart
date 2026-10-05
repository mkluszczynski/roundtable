import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/project_tools.dart';
import 'package:test/test.dart';

Future<List<String>> _detect(Map<String, String> repo) async {
  final tools = await detectProjectTools(
    paths: repo.keys.toList(),
    read: (path) async => repo[path],
  );
  return [for (final t in tools) '${t.name}@${t.version}'];
}

const _flutterPubspec = '''
name: app
dependencies:
  flutter:
    sdk: flutter
''';

void main() {
  group('detectProjectTools', () {
    test('a Flutter package in a monorepo means flutter, not dart', () async {
      expect(
        await _detect({
          'pubspec.yaml': 'name: workspace\n',
          'server/pubspec.yaml': 'name: server\n',
          'app/pubspec.yaml': _flutterPubspec,
        }),
        ['flutter@latest'],
      );
    });

    test('a serverpod dependency adds its CLI at the same version', () async {
      expect(
        await _detect({
          'app/pubspec.yaml': _flutterPubspec,
          'server/pubspec.yaml':
              'dependencies:\n  serverpod: ^4.0.3\n'
              '  serverpod_test: 4.0.3\n',
        }),
        ['flutter@latest', 'pub:serverpod_cli@4.0.3'],
      );
      expect(
        await _detect({
          'pubspec.yaml': 'dependencies:\n  serverpod: ">=4.0.0"\n',
        }),
        ['dart@latest', 'pub:serverpod_cli@latest'],
      );
    });

    test('a plain Dart package means dart', () async {
      expect(await _detect({'pubspec.yaml': 'name: cli\n'}), ['dart@latest']);
    });

    test('.fvmrc pins the Flutter version', () async {
      expect(
        await _detect({
          'pubspec.yaml': _flutterPubspec,
          '.fvmrc': '{"flutter": "3.24.0"}',
        }),
        ['flutter@3.24.0'],
      );
    });

    test('node from .nvmrc and the packageManager field', () async {
      expect(
        await _detect({
          'package.json': '{"packageManager": "pnpm@9.1.0+sha512.abc"}',
          '.nvmrc': 'v20.11.1\n',
        }),
        ['node@20.11.1', 'pnpm@9.1.0'],
      );
    });

    test('node without a version file uses lts', () async {
      expect(await _detect({'web/package.json': '{}'}), ['node@lts']);
    });

    test('go version comes from go.mod', () async {
      expect(
        await _detect({'go.mod': 'module x\n\ngo 1.22.3\n'}),
        ['go@1.22.3'],
      );
    });

    test('python, rust, ruby and java are detected by manifest', () async {
      expect(
        await _detect({
          'pyproject.toml': '',
          '.python-version': '3.12\n',
          'Cargo.toml': '',
          'Gemfile': '',
          'pom.xml': '',
        }),
        ['python@3.12', 'rust@latest', 'ruby@latest', 'java@latest'],
      );
    });

    test("a Flutter app's platform folders don't add java", () async {
      expect(
        await _detect({
          'app/pubspec.yaml': _flutterPubspec,
          'app/android/build.gradle': '',
          'app/web/package.json': '{}',
          'tools/pom.xml': '',
        }),
        ['flutter@latest', 'java@latest'],
      );
    });

    test('manifests in dependency and build dirs are ignored', () async {
      expect(
        await _detect({
          'node_modules/x/package.json': '{}',
          'build/pubspec.yaml': 'name: x\n',
          'a/b/c/d/go.mod': 'go 1.21\n',
        }),
        isEmpty,
      );
    });

    test('a root mise config wins over detection', () async {
      expect(
        await _detect({
          'pubspec.yaml': _flutterPubspec,
          '.mise.toml':
              '[env]\nX = "1"\n[tools]\nnode = "22" # comment\n'
              'python = ["3.12", "3.11"]\n',
        }),
        ['node@22', 'python@3.12'],
      );
    });

    test('.tool-versions is used, with nodejs renamed to node', () async {
      expect(
        await _detect({
          'package.json': '{}',
          '.tool-versions': 'nodejs 20.1.0\n# x\nflutter 3.24.0-stable\n',
        }),
        ['node@20.1.0', 'flutter@3.24.0-stable'],
      );
    });
  });

  group('validateProjectTools', () {
    test('trims and lowercases names', () {
      final tools = validateProjectTools([
        ProjectTool(name: ' Flutter ', version: ' 3.24 '),
        ProjectTool(name: 'aqua:cli/cli', version: 'latest'),
      ]);
      expect(
        [for (final t in tools) '${t.name}@${t.version}'],
        [
          'flutter@3.24',
          'aqua:cli/cli@latest',
        ],
      );
    });

    for (final (name, version) in [
      ('', '1'),
      ('node; rm -rf /', '1'),
      ('node', ''),
      ('node', '20 && x'),
    ]) {
      test('rejects "$name" "$version"', () {
        expect(
          () => validateProjectTools([
            ProjectTool(name: name, version: version),
          ]),
          throwsA(isA<InvalidStateException>()),
        );
      });
    }

    test('a pub: tool needs dart or flutter', () {
      expect(
        () => validateProjectTools([
          ProjectTool(name: 'pub:serverpod_cli', version: '4.0.3'),
        ]),
        throwsA(isA<InvalidStateException>()),
      );
      expect(
        validateProjectTools([
          ProjectTool(name: 'flutter', version: 'latest'),
          ProjectTool(name: 'pub:serverpod_cli', version: '4.0.3'),
        ]),
        hasLength(2),
      );
    });

    test('rejects duplicates', () {
      expect(
        () => validateProjectTools([
          ProjectTool(name: 'node', version: '20'),
          ProjectTool(name: 'Node', version: '22'),
        ]),
        throwsA(isA<InvalidStateException>()),
      );
    });
  });
}
