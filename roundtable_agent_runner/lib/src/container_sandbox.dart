import 'dart:io';

/// The image a docker-mode agent runs in unless its project sets
/// `Project.dockerImage`: Debian with git and curl. Everything else comes
/// from the host — `claude` and the project's toolchains are mounted in.
const defaultContainerImage = 'docker.io/library/buildpack-deps:bookworm-scm';

/// What a task's run needs from its container — see
/// `TaskDispatcher.sandboxFor`. [readOnlyDirectories] hold the run's MCP
/// config and attached images; [image] is `Project.dockerImage`.
typedef ContainerRequest = ({
  int projectId,
  int taskId,
  String worktreePath,
  List<String> readOnlyDirectories,
  String? image,
});

/// One host path visible inside the container, at the same path.
typedef ContainerMount = ({String path, bool readOnly});

/// Runs `claude` inside a rootless Podman container for a docker-mode agent
/// (`AgentExecutionMode.docker`, docs/FLOWS.md §8): the agent sees only
/// what's mounted — its task's worktree, the project's git data, the
/// toolchains and its own home — instead of the whole machine.
///
/// Mounts keep their host paths, so worktree paths, the toolchains' `PATH`
/// and the MCP config work unchanged. `--userns=keep-id` runs the container
/// as the runner's own user, so files it writes are the runner's to commit,
/// and a container can never get more rights than the runner already has.
class ContainerSandbox {
  ContainerSandbox({
    required this.image,
    required this.name,
    required this.workingDirectory,
    required this.mounts,
    required this.home,
    required this.claudePath,
    this.podman = 'podman',
  });

  /// The absolute path of the host's `claude` binary, mounted read-only and
  /// run from there.
  final String claudePath;

  final String image;

  /// The container's name (`roundtable-task-12`), to remove a leftover one.
  final String name;
  final String workingDirectory;
  final List<ContainerMount> mounts;

  /// `$HOME` inside the container — a per-project directory on the host, so
  /// Claude Code's sessions (needed to resume) survive the container.
  final String home;
  final String podman;

  /// The `podman` arguments that run [executable] with [args]. Variables in
  /// [environment] are passed by name only (`-e NAME`), so their values — the
  /// OAuth token — never show up in the process list: podman reads them from
  /// its own environment, which the caller sets.
  List<String> runArgs(
    String executable,
    List<String> args, {
    Iterable<String> environment = const [],
  }) => [
    // No systemd user session under the runner's service.
    '--cgroup-manager=cgroupfs',
    '--events-backend=file',
    'run',
    '--rm',
    '--init',
    '--name',
    name,
    '--userns=keep-id',
    '--workdir',
    workingDirectory,
    for (final mount in {for (final m in mounts) m.path: m}.values) ...[
      '--volume',
      '${mount.path}:${mount.path}${mount.readOnly ? ':ro' : ''}',
    ],
    '--env',
    'HOME=$home',
    for (final name in environment) ...['--env', name],
    image,
    executable,
    ...args,
  ];

  /// Removes the container if it outlived its run (the runner was killed
  /// mid-task, or `podman run` didn't forward a cancel).
  Future<void> remove() async {
    try {
      await Process.run(podman, [
        '--cgroup-manager=cgroupfs',
        '--events-backend=file',
        'rm',
        '--force',
        '--ignore',
        name,
      ]);
    } on ProcessException {
      // Podman is gone — nothing to clean up.
    }
  }
}

/// [serverUrl] as reachable from inside a container: rootless Podman
/// can't reach the host's loopback, but maps the host as
/// `host.containers.internal`.
String containerServerUrl(String serverUrl) {
  final uri = Uri.tryParse(serverUrl);
  if (uri == null) return serverUrl;
  const loopback = {'localhost', '127.0.0.1', '::1', '[::1]'};
  if (!loopback.contains(uri.host)) return serverUrl;
  return uri.replace(host: 'host.containers.internal').toString();
}

/// [error] from a failed container run, with the fix appended when it's a
/// known machine setup problem rather than the agent's.
String? describeContainerFailure(String? error) {
  if (error == null) return null;
  if (error.contains('newuidmap') || error.contains('newgidmap')) {
    return '$error\n\nRootless podman can\'t map the container\'s users: '
        'the runner service needs NoNewPrivileges=false and the account '
        'needs subuid/subgid ranges. Re-run install-agent.sh with --docker.';
  }
  return error;
}
