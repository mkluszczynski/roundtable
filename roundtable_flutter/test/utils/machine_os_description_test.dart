import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/machine_os_description.dart';

void main() {
  Machine machine({String? osVersion, String? hostInfo}) =>
      Machine(name: 'VPS', osVersion: osVersion, hostInfo: hostInfo);

  test('prefers the detected OS version over the hand-typed host info', () {
    expect(
      machine(
        osVersion: 'Ubuntu 24.04',
        hostInfo: 'Hetzner · Ubuntu 22.04',
      ).osDescription,
      'Ubuntu 24.04',
    );
  });

  test('falls back to the host info when no OS version was reported', () {
    expect(
      machine(hostInfo: 'Hetzner · Ubuntu 22.04').osDescription,
      'Hetzner · Ubuntu 22.04',
    );
  });

  test('is null when neither is set', () {
    expect(machine().osDescription, isNull);
  });
}
