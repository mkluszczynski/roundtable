/// Maps a filename's extension to a `highlight` package language id
/// (`widgets/diff_view.dart`), per the ids in `package:highlight/languages/`.
const _extensionLanguages = <String, String>{
  'dart': 'dart',
  'ts': 'typescript',
  'tsx': 'typescript',
  'js': 'javascript',
  'jsx': 'javascript',
  'mjs': 'javascript',
  'cjs': 'javascript',
  'py': 'python',
  'rb': 'ruby',
  'go': 'go',
  'rs': 'rust',
  'java': 'java',
  'kt': 'kotlin',
  'kts': 'kotlin',
  'swift': 'swift',
  'c': 'c',
  'h': 'c',
  'cc': 'cpp',
  'cpp': 'cpp',
  'cxx': 'cpp',
  'hpp': 'cpp',
  'cs': 'csharp',
  'php': 'php',
  'sh': 'bash',
  'bash': 'bash',
  'zsh': 'bash',
  'yaml': 'yaml',
  'yml': 'yaml',
  'json': 'json',
  'sql': 'sql',
  'md': 'markdown',
  'html': 'xml',
  'htm': 'xml',
  'xml': 'xml',
  'css': 'css',
  'scss': 'scss',
  'less': 'less',
  'graphql': 'graphql',
  'proto': 'protobuf',
  'toml': 'ini',
  'ini': 'ini',
  'lua': 'lua',
  'pl': 'perl',
  'groovy': 'groovy',
};

/// Returns the `highlight` package language id for [filename], or `null`
/// when the extension isn't recognized (the caller then falls back to
/// unhighlighted plain text).
String? languageForFilename(String filename) {
  final base = filename.split('/').last.toLowerCase();
  if (base == 'dockerfile') return 'dockerfile';
  if (base == 'makefile') return 'makefile';

  final dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) return null;
  return _extensionLanguages[base.substring(dot + 1)];
}
