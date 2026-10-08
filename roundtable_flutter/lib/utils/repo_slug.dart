/// `https://github.com/owner/repo(.git)` → `owner/repo`; [url] itself when
/// it has no path to show.
String repoSlug(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final slug = uri.pathSegments
      .where((s) => s.isNotEmpty)
      .join('/')
      .replaceFirst(RegExp(r'\.git$'), '');
  return slug.isEmpty ? url : slug;
}
