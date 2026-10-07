import 'package:roundtable_client/roundtable_client.dart';

extension MachineOsDescription on Machine {
  /// The OS the daemon detected (e.g. "Ubuntu 24.04"), or the legacy
  /// hand-typed host label for runners that predate OS detection.
  String? get osDescription => osVersion ?? hostInfo;
}
