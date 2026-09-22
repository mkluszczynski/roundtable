/// Compact relative-time formatting shared by machine/project detail and
/// list cards ("Offline — last seen 2h ago", "last reported 8s ago",
/// "registered 41 days ago"). [words] spells out the unit ("41 days ago"
/// instead of "41d ago") for header-line prose.
String relativeTime(DateTime at, {bool words = false}) {
  final elapsed = DateTime.now().difference(at);
  if (elapsed.inSeconds < 60) {
    return words ? 'just now' : '${elapsed.inSeconds}s ago';
  }
  if (elapsed.inMinutes < 60) {
    return words
        ? '${elapsed.inMinutes} minutes ago'
        : '${elapsed.inMinutes}m ago';
  }
  if (elapsed.inHours < 24) {
    return words ? '${elapsed.inHours} hours ago' : '${elapsed.inHours}h ago';
  }
  return words ? '${elapsed.inDays} days ago' : '${elapsed.inDays}d ago';
}
