import 'dart:io';

import 'package:crypto/crypto.dart';

/// Version string of this install: short content hashes of the daemon
/// binary and the permission-prompt-tool binary. Must match
/// `agentRunnerVersion` on the server, which computes it over the binaries
/// it serves — a mismatch is what the panel shows as "update available".
///
/// Returns null when either binary isn't a compiled install (e.g. a
/// dev-mode `dart run` from a repo checkout), since there's nothing to
/// compare or update then.
String? installedRunnerVersion({
  required String executablePath,
  required String? permissionPromptToolPath,
}) {
  if (permissionPromptToolPath == null) return null;
  final runner = File(executablePath);
  final tool = File(permissionPromptToolPath);
  if (!runner.existsSync() || !tool.existsSync()) return null;
  return '${_shortHash(runner)}-${_shortHash(tool)}';
}

String _shortHash(File file) =>
    sha256.convert(file.readAsBytesSync()).toString().substring(0, 12);

/// Hands an update off to the root-side updater `scripts/install-agent.sh`
/// installs: its `agent-runner-update.path` systemd unit watches
/// [flagPath] and, when it appears, re-downloads both binaries from the
/// server and restarts this service. The daemon itself can't replace its
/// root-owned binaries — it runs unprivileged with `NoNewPrivileges`.
///
/// Returns false if the flag couldn't be written.
bool requestRunnerUpdate(String flagPath) {
  try {
    File(flagPath).writeAsStringSync(DateTime.now().toUtc().toIso8601String());
    return true;
  } on FileSystemException {
    return false;
  }
}
