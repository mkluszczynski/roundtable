import 'dart:convert';

import '../generated/protocol.dart';

/// The first word of the first line: `.python-version`, `.ruby-version`…
String firstLine(String content) =>
    content.split('\n').first.trim().split(RegExp(r'\s')).first;

bool dependsOnFlutter(String pubspec) =>
    RegExp(r'^\s+sdk:\s*flutter\s*$', multiLine: true).hasMatch(pubspec);

/// The `serverpod:` dependency's version (`4.0.3`, `^4.0.3` → `4.0.3`), or
/// `latest` for a range it can't pin; null without serverpod.
String? serverpodVersion(String pubspec) {
  final match = RegExp(
    r'^\s+serverpod:\s*(.*)$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) return null;
  final spec = match.group(1)!.trim().replaceAll(RegExp('["\']'), '');
  final version = RegExp(r'^\^?(\d+\.\d+\.\d+)$').firstMatch(spec);
  return version?.group(1) ?? 'latest';
}

/// `.fvmrc` is JSON (`{"flutter": "3.24.0"}`); a channel isn't a version.
String fvmVersion(String content) {
  try {
    final version = (jsonDecode(content) as Map<String, dynamic>)['flutter'];
    if (version is String && RegExp(r'^\d').hasMatch(version)) return version;
  } on FormatException {
    // Not JSON — no version.
  }
  return '';
}

/// `.nvmrc`: `v20.11.1`, `20` or an alias like `lts/iron`.
String nodeVersion(String content) {
  final line = firstLine(content);
  if (line.startsWith('lts/')) return 'lts';
  final version = line.startsWith('v') ? line.substring(1) : line;
  return RegExp(r'^\d').hasMatch(version) ? version : '';
}

/// `go 1.22` in go.mod, or null.
String? goVersion(String goMod) => RegExp(
  r'^go (\d+\.\d+(?:\.\d+)?)',
  multiLine: true,
).firstMatch(goMod)?.group(1);

/// `"packageManager": "pnpm@9.1.0+sha512..."` in package.json.
({String name, String version})? packageManager(String packageJson) {
  try {
    final value =
        (jsonDecode(packageJson) as Map<String, dynamic>)['packageManager'];
    if (value is! String) return null;
    final match = RegExp(
      r'^(pnpm|yarn|bun)@(\d[^+]*)',
    ).firstMatch(value.trim());
    if (match == null) return null;
    return (name: match.group(1)!, version: match.group(2)!);
  } on FormatException {
    return null;
  }
}

/// The `[tools]` table of a mise config: `node = "20"` or
/// `python = ["3.12", "3.11"]` (first one wins).
List<ProjectTool> parseMiseToml(String content) {
  final tools = <ProjectTool>[];
  var inTools = false;
  for (final raw in content.split('\n')) {
    final line = raw.split('#').first.trim();
    if (line.startsWith('[')) {
      inTools = line == '[tools]';
      continue;
    }
    if (!inTools || !line.contains('=')) continue;
    final eq = line.indexOf('=');
    final name = line.substring(0, eq).trim().replaceAll('"', '');
    final version = RegExp(
      r'"([^"]+)"',
    ).firstMatch(line.substring(eq))?.group(1);
    if (name.isNotEmpty && version != null) {
      tools.add(ProjectTool(name: name, version: version));
    }
  }
  return tools;
}

/// `.tool-versions`: `nodejs 20.11.1` per line (asdf names `nodejs`).
List<ProjectTool> parseToolVersions(String content) => [
  for (final raw in content.split('\n'))
    if (raw.split('#').first.trim().split(RegExp(r'\s+')) case [
      final name,
      final version,
      ...,
    ] when name.isNotEmpty)
      ProjectTool(name: name == 'nodejs' ? 'node' : name, version: version),
];
