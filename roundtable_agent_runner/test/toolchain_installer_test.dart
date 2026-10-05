import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  test('miseConfig quotes every tool under [tools]', () {
    expect(
      miseConfig([
        ProjectTool(name: 'node', version: 'lts'),
        ProjectTool(name: 'npm:prettier', version: '3'),
      ]),
      endsWith('[tools]\n"node" = "lts"\n"npm:prettier" = "3"'),
    );
  });

  test('missingTools lists resolved versions', () {
    expect(
      missingTools(
        '{"node": [{"version": "24.21.0", "requested_version": "lts"}],'
        ' "flutter": [{"requested_version": "latest"}]}',
      ),
      ['node 24.21.0', 'flutter latest'],
    );
    expect(missingTools(''), isEmpty);
    expect(missingTools('{}'), isEmpty);
  });

  test('lastLines keeps the tail of the output', () {
    expect(lastLines('a\nb\nc\n', count: 2), 'b\nc');
  });

  test('miseConfig leaves pub: tools out', () {
    expect(
      miseConfig([
        ProjectTool(name: 'flutter', version: 'latest'),
        ProjectTool(name: 'pub:serverpod_cli', version: '4.0.3'),
      ]),
      isNot(contains('serverpod')),
    );
  });

  test('activePubPackages and pubToolActive', () {
    final active = activePubPackages(
      'serverpod_cli 4.0.3\nmelos 6.1.0 at path "/x"\n',
    );
    expect(active, {'serverpod_cli': '4.0.3', 'melos': '6.1.0'});
    bool isActive(String name, String version) =>
        pubToolActive(ProjectTool(name: name, version: version), active);
    expect(isActive('pub:serverpod_cli', '4.0.3'), isTrue);
    expect(isActive('pub:serverpod_cli', '4.0.4'), isFalse);
    expect(isActive('pub:melos', 'latest'), isTrue);
    expect(isActive('pub:very_good_cli', 'latest'), isFalse);
  });
}
