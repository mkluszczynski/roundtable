import 'dart:io';

import 'container_sandbox.dart';

/// Builds the container of a docker-mode agent's run (docs/FLOWS.md §8):
/// what it mounts decides what a run can reach on the machine.
class SandboxFactory {
  SandboxFactory({
    required this.home,
    required this.workspaceRoot,
    required this.claudeExecutable,
    required this.permissionPromptToolCommand,
    required this.hasPodman,
  });

  /// The service account's home: toolchains, pub cache and per-project
  /// container homes live under it.
  final String home;
  final String workspaceRoot;
  final String claudeExecutable;
  final List<String> permissionPromptToolCommand;

  /// Whether podman was detected on this machine.
  final bool Function() hasPodman;

  /// The container for [request]: the worktree read-write, the project's
  /// bare repo read-only (git on the host runs its config and hooks), the
  /// toolchains and pub cache read-write (Flutter writes into its own SDK),
  /// `claude` and the permission-prompt-tool read-only, and a home per
  /// project, so Claude Code's sessions survive for `--resume`.
  ContainerSandbox build(ContainerRequest request) {
    if (!hasPodman()) {
      throw StateError(
        'this agent runs in docker mode, but podman is not installed on this '
        'machine — re-run install-agent.sh with --docker, or switch the agent '
        'to native',
      );
    }
    final containerHome = Directory(
      '$home/containers/project-${request.projectId}',
    )..createSync(recursive: true);
    _copyClaudeCredentials(containerHome.path);
    final claude = resolveExecutable(claudeExecutable);
    final workspace = Directory(workspaceRoot).absolute.path;
    final shared = ['$home/.local/share/mise', '$home/.pub-cache'];
    for (final dir in shared) {
      Directory(dir).createSync(recursive: true);
    }
    return ContainerSandbox(
      image: request.image?.trim().isNotEmpty == true
          ? request.image!.trim()
          : defaultContainerImage,
      name: request.name,
      workingDirectory: request.worktreePath,
      home: containerHome.path,
      claudePath: claude,
      podman: resolveExecutable('podman'),
      mounts: [
        (path: request.worktreePath, readOnly: false),
        (path: '$workspace/${request.projectId}/repo.git', readOnly: true),
        (path: containerHome.path, readOnly: false),
        for (final dir in shared) (path: dir, readOnly: false),
        (path: claude, readOnly: true),
        if (permissionPromptToolCommand case [final tool])
          (path: tool, readOnly: true),
        for (final dir in request.readOnlyDirectories)
          (path: dir, readOnly: true),
      ],
    );
  }

  /// A machine logged in with `claude login` (no `CLAUDE_CODE_OAUTH_TOKEN`)
  /// keeps its credentials in `~/.claude`; containers get a copy, never the
  /// rest of that directory (other projects' sessions).
  void _copyClaudeCredentials(String containerHome) {
    final credentials = File('$home/.claude/.credentials.json');
    if (!credentials.existsSync()) return;
    Directory('$containerHome/.claude').createSync(recursive: true);
    final copy = File('$containerHome/.claude/.credentials.json');
    // Created owner-only before the secret goes in, like ClaudeTokenStore.
    copy.writeAsStringSync('');
    Process.runSync('chmod', ['600', copy.path]);
    copy.writeAsBytesSync(credentials.readAsBytesSync());
  }

  /// The absolute, symlink-free path of [executable] (a path or a name on
  /// PATH), so it can be mounted into a container.
  static String resolveExecutable(String executable) {
    if (!executable.contains('/')) {
      for (final dir in (Platform.environment['PATH'] ?? '').split(':')) {
        if (dir.isNotEmpty && File('$dir/$executable').existsSync()) {
          executable = '$dir/$executable';
          break;
        }
      }
    }
    return File(executable).resolveSymbolicLinksSync();
  }
}
