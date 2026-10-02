import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('runner_update'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('installedRunnerVersion', () {
    test('changes when either binary changes', () {
      final runner = File('${dir.path}/runner')..writeAsStringSync('a');
      final tool = File('${dir.path}/tool')..writeAsStringSync('b');
      String? version() => installedRunnerVersion(
        executablePath: runner.path,
        permissionPromptToolPath: tool.path,
      );

      final first = version();
      expect(first, matches(RegExp(r'^[0-9a-f]{12}-[0-9a-f]{12}$')));
      expect(version(), first);

      tool.writeAsStringSync('c');
      expect(version(), isNot(first));
    });

    test('is null without a compiled permission tool', () {
      expect(
        installedRunnerVersion(
          executablePath: Platform.resolvedExecutable,
          permissionPromptToolPath: null,
        ),
        isNull,
      );
    });
  });

  group('requestRunnerUpdate', () {
    test('writes the flag file', () {
      final flag = '${dir.path}/update-requested';
      expect(requestRunnerUpdate(flag), isTrue);
      expect(File(flag).existsSync(), isTrue);
    });

    test('returns false when the flag cannot be written', () {
      expect(requestRunnerUpdate('${dir.path}/missing/flag'), isFalse);
    });
  });
}
