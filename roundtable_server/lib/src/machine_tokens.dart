import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';

/// Hashes a machine's raw registration token for storage; only the hash is
/// ever persisted.
String hashMachineToken(String token) =>
    sha256.convert(utf8.encode(token)).toString();

/// The machine [token] belongs to. Throws [InvalidTokenException] for an
/// unknown or revoked token — the daemon treats that as fatal.
Future<Machine> findMachineByToken(Session session, String token) async {
  final machine = await Machine.db.findFirstRow(
    session,
    where: (t) => t.tokenHash.equals(hashMachineToken(token)),
  );
  if (machine == null) {
    throw InvalidTokenException(
      message: 'Unknown or revoked registration token',
    );
  }
  return machine;
}
