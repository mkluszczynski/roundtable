import 'dart:async';
import 'dart:io';

/// A command-line tool the runner looked for; [version] is null when it
/// isn't on this machine's `PATH`.
typedef ToolInfo = ({String name, String? version});

/// Tools worth telling the agent about — the usual build/test toolchains.
const probedTools = [
  'git',
  'dart',
  'flutter',
  'node',
  'npm',
  'pnpm',
  'python3',
  'pip3',
  'go',
  'cargo',
  'java',
  'docker',
  'make',
];

/// Runs `<tool> --version` for each of [tools] and keeps the first line of
/// output. A tool that can't be launched is reported missing.
Future<List<ToolInfo>> detectToolchain({
  List<String> tools = probedTools,
  Duration timeout = const Duration(seconds: 20),
}) {
  return Future.wait([for (final tool in tools) _probe(tool, timeout)]);
}

Future<ToolInfo> _probe(String tool, Duration timeout) async {
  try {
    final result = await Process.run(tool, ['--version']).timeout(timeout);
    final output = '${result.stdout}\n${result.stderr}'
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    return (name: tool, version: output.isEmpty ? 'unknown version' : output);
  } on ProcessException {
    return (name: tool, version: null);
  } on TimeoutException {
    // Present but slow (e.g. flutter's first-run setup) — still usable.
    return (name: tool, version: 'unknown version');
  }
}

/// Appended to Claude Code's system prompt (`--append-system-prompt`) on
/// every run, so the agent plans for the machine it's actually on instead
/// of a developer's interactive setup.
String buildEnvironmentPrompt({
  required String machineName,
  required String user,
  required List<ToolInfo> tools,
  bool review = false,
}) {
  final available = tools.where((t) => t.version != null);
  final missing = tools.where((t) => t.version == null).map((t) => t.name);
  final availableList = available.isEmpty
      ? '- (none detected)'
      : available.map((t) => '- ${t.name}: ${t.version}').join('\n');

  return '''
# Execution environment (Roundtable)

You are running unattended through the Roundtable agent runner on the machine "$machineName", as the system user `$user`, inside an isolated git worktree of the project. Nobody is watching this session: the developer only sees your log, ${review ? 'and the review you return' : 'answers questions you ask with AskUserQuestion, approves your plan, and reviews the pull request opened from your branch'}.

Tools available on this machine's PATH:
$availableList
${missing.isEmpty ? '' : 'Not installed here: ${missing.join(', ')}.\n'}
What this environment does NOT have:
- No MCP servers from the repository's configuration (only Roundtable's own tools are loaded).
- No running app server, database, emulator or browser — you cannot hot reload, restart, open or click through the app.
- Instructions in CLAUDE.md, AGENTS.md or similar files that assume a developer's interactive setup (MCP tools, running servers, manual UI checks) do not apply here.

How your work is delivered:
${review ? '- You only review; never change files, commit or push.' : '''- Do NOT commit, push, create branches or open pull requests yourself. When your run ends, Roundtable commits every change in the worktree, pushes it and opens the pull request automatically.
- Your final message becomes the pull request description: summarize what you changed and why.
- Never end by asking whether to commit, open a PR or continue — nobody can answer a plain message. If you need a decision, use AskUserQuestion; otherwise finish the work and stop.
- If the task needs no code change (e.g. it is a question), answer it in your final message and change nothing — that answer is shown as the task's result.'''}

How to verify your work:
- Use only the tools listed above (e.g. a project's analyzer, formatter or unit tests when their toolchain is available).
- A missing toolchain never blocks the work itself: write the code anyway (even when you can't generate code, run migrations or build), and report what you couldn't run. Only say you can't do something when it's impossible without the tool.
- Do not try to install missing toolchains, use sudo, or work around a missing tool.
- When a verification step can't run here, say so in your plan and list it ${review ? 'in your review' : 'in your final message under a "Not verified here" heading'}, so the developer runs it.''';
}
