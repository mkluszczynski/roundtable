import 'package:roundtable_client/roundtable_client.dart';

import 'claude_code_executor.dart';
import 'container_sandbox.dart';
import 'environment_prompt.dart';
import 'stream_json_formatter.dart';
import 'toolchain_installer.dart';

/// Where one run's `claude` runs — on the machine, or in a container for a
/// docker-mode agent (docs/FLOWS.md §8) — with the project's toolchains.
/// Shared by task runs and code reviews.
class RunEnvironment {
  RunEnvironment._(
    this.executor,
    this.sandbox,
    this.toolchain,
    this._machinePrompt,
  );

  final ClaudeCodeExecutor executor;

  /// The run's container; null for a native agent.
  final ContainerSandbox? sandbox;
  final PreparedToolchain? toolchain;
  final String? _machinePrompt;

  bool get inContainer => sandbox != null;

  /// The toolchains' `PATH` for `claude`, if any were installed.
  Map<String, String>? get environment => toolchain?.environment;

  /// The `--append-system-prompt`: this machine (or container), the
  /// project's toolchains, then [extra]. Null when there's nothing to say.
  String? systemPrompt([List<String> extra = const []]) {
    final toolchain = this.toolchain;
    final prompt = [
      ?_machinePrompt,
      if (toolchain != null) projectToolchainPrompt(toolchain.tools),
      ...extra,
    ].join('\n\n');
    return prompt.isEmpty ? null : prompt;
  }

  /// A failed run's reason, explained for a container where that helps.
  String? describeFailure(String? errorSummary) =>
      inContainer ? describeContainerFailure(errorSummary) : errorSummary;

  /// Removes the container if it outlived the run.
  Future<void> dispose() async => sandbox?.remove();
}

/// Builds a [RunEnvironment] for each run, from the machine's executor,
/// container runtime and toolchain installer.
class RunEnvironments {
  RunEnvironments({
    required this.executorFactory,
    required this.log,
    this.sandboxFor,
    this.toolchainInstaller,
    this.fetchProject,
    this.environmentPrompt,
  });

  final ClaudeCodeExecutor Function() executorFactory;
  final ContainerSandbox Function(ContainerRequest request)? sandboxFor;
  final ToolchainInstaller? toolchainInstaller;
  final Future<Project?> Function(int projectId)? fetchProject;
  final String? Function({bool container})? environmentPrompt;
  final void Function(String message) log;

  /// Prepares [agent]'s run on [projectId]'s [worktreePath]: installs the
  /// project's toolchains (unless [installToolchain] is false) and, for a
  /// docker-mode agent, the container named [containerName], which also
  /// sees [readOnlyDirectories]. Progress goes to [append]; [label] names
  /// the run in the daemon's log. Throws when a docker-mode agent is on a
  /// machine without a container runtime.
  Future<RunEnvironment> prepare({
    required Agent agent,
    required String label,
    required int projectId,
    required String containerName,
    required String worktreePath,
    required void Function(LogItem item) append,
    List<String> readOnlyDirectories = const [],
    bool installToolchain = true,
  }) async {
    final inContainer = agent.executionMode == AgentExecutionMode.docker;
    final build = sandboxFor;
    if (inContainer && build == null) {
      throw StateError(
        '${agent.name} runs in docker mode, but this machine has no '
        'container runtime — install podman (install-agent.sh --docker) '
        'or switch the agent to native',
      );
    }
    final project = await fetchProject?.call(projectId);
    final toolchain = installToolchain
        ? await prepareToolchainForRun(
            toolchainInstaller,
            label,
            projectId,
            project?.tools ?? const [],
            append,
            log,
          )
        : null;
    ContainerSandbox? sandbox;
    if (build != null && inContainer) {
      sandbox = build((
        projectId: projectId,
        name: containerName,
        worktreePath: worktreePath,
        readOnlyDirectories: readOnlyDirectories,
        image: project?.dockerImage,
      ));
      append(
        LogItem(
          kind: LogKind.event,
          content: 'Running in a container (${sandbox.image})',
        ),
      );
    }
    return RunEnvironment._(
      sandbox == null
          ? executorFactory()
          : executorFactory().inContainer(sandbox),
      sandbox,
      toolchain,
      environmentPrompt?.call(container: inContainer),
    );
  }
}

/// Installs the project's toolchains before a run, reporting a download
/// on the task's timeline. A failure is logged there too, but doesn't
/// fail the task: the agent works on and reports what it couldn't verify.
Future<PreparedToolchain?> prepareToolchainForRun(
  ToolchainInstaller? installer,
  String label,
  int projectId,
  List<ProjectTool> tools,
  void Function(LogItem item) append,
  void Function(String message) log,
) async {
  if (installer == null || tools.isEmpty) return null;
  try {
    var installed = false;
    final prepared = await installer.prepare(
      projectId: projectId,
      tools: tools,
      onInstalling: (missing) {
        installed = true;
        log('$label: installing ${missing.join(', ')}');
        append(
          LogItem(
            kind: LogKind.event,
            content:
                'Installing ${missing.join(', ')} — the first time takes '
                'a few minutes',
          ),
        );
      },
    );
    if (installed) {
      append(
        LogItem(
          kind: LogKind.event,
          content: 'Tools ready: ${prepared.tools.join(', ')}',
        ),
      );
    }
    return prepared;
  } catch (e) {
    log('$label: toolchain install failed: $e');
    append(
      LogItem(
        kind: LogKind.event,
        content: "Couldn't install the project's tools: $e",
        isError: true,
      ),
    );
    return null;
  }
}
