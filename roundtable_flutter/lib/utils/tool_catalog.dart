/// A toolchain the panel offers by name. [name] is the mise tool id the
/// runner installs; [versionHint] shows what a version looks like.
typedef CatalogTool = ({String name, String label, String versionHint});

/// The common toolchains, in the "Add tool" menu. Anything else mise knows
/// can still be added by id ("Other…").
const toolCatalog = <CatalogTool>[
  (name: 'flutter', label: 'Flutter (includes Dart)', versionHint: '3.24.0'),
  (name: 'dart', label: 'Dart', versionHint: '3.5.0'),
  (name: 'node', label: 'Node.js', versionHint: '20 or lts'),
  (name: 'pnpm', label: 'pnpm', versionHint: '9'),
  (name: 'python', label: 'Python', versionHint: '3.12'),
  (name: 'go', label: 'Go', versionHint: '1.22'),
  (name: 'java', label: 'Java', versionHint: '21'),
  (name: 'rust', label: 'Rust', versionHint: '1.80'),
  (name: 'ruby', label: 'Ruby', versionHint: '3.3'),
];

/// The catalog label for mise id [name], or the id itself.
String toolLabel(String name) =>
    toolCatalog.where((t) => t.name == name).firstOrNull?.label ?? name;

/// Explains the tools section in the project dialogs.
const toolsDescription =
    'Installed on the machine (via mise) before each task, so agents can '
    'run tests and analyzers. The first task with a new tool waits a few '
    'minutes for the download.';
