import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

/// The Claude Code OAuth token set in the panel (docs/FLOWS.md §1), kept in
/// a file only the service account can read. It takes precedence over the
/// token from the install (`CLAUDE_CODE_OAUTH_TOKEN` in config.env), which
/// the daemon can't rewrite: that file belongs to root. install-agent.sh
/// deletes it when it's given a new `--claude-token`.
class ClaudeTokenStore {
  ClaudeTokenStore(this.path, {this.installToken, this.loginCredentialsPath});

  final String path;

  /// The token config.env was installed with, if any.
  final String? installToken;

  /// `~/.claude/.credentials.json`, written by `claude login`.
  final String? loginCredentialsPath;

  String? _saved;
  var _loaded = false;

  String? get _panelToken {
    if (!_loaded) {
      _loaded = true;
      try {
        final saved = File(path).readAsStringSync().trim();
        if (saved.isNotEmpty) _saved = saved;
      } on FileSystemException {
        // Nothing set from the panel yet.
      }
    }
    return _saved;
  }

  /// The token `claude` runs with: the one from the panel, else the
  /// install's. Null means `claude login` credentials, if any.
  String? get token => _panelToken ?? installToken;

  /// Where the credentials `claude` runs with come from, for the panel.
  ClaudeAuthSource get source {
    if (_panelToken != null) return ClaudeAuthSource.panel;
    if (installToken != null && installToken!.isNotEmpty) {
      return ClaudeAuthSource.install;
    }
    final login = loginCredentialsPath;
    if (login != null && File(login).existsSync()) {
      return ClaudeAuthSource.login;
    }
    return ClaudeAuthSource.none;
  }

  /// Saves [token] (owner read/write only) and uses it from the next run on.
  /// Throws if it can't be saved privately; the server then keeps the token
  /// for the next attempt.
  Future<void> save(String token) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    // Locked down while still empty, then filled and moved into place, so
    // the token is never readable by others, even briefly.
    final temp = File('$path.tmp');
    await temp.writeAsString('');
    final chmod = await Process.run('chmod', ['600', temp.path]);
    if (chmod.exitCode != 0) {
      await temp.delete();
      throw FileSystemException('chmod 600 failed: ${chmod.stderr}', path);
    }
    await temp.writeAsString(token, flush: true);
    await temp.rename(path);
    _saved = token;
    _loaded = true;
  }
}
