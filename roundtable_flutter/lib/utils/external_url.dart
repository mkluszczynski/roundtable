import 'package:url_launcher/url_launcher.dart';

/// [url] if it's an `https` link — the only kind the panel opens. The URLs
/// it opens come from the server, GitHub or an agent; a `file:`,
/// `javascript:` or custom-scheme one could do more than show a page.
Uri? safeExternalUri(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
      ? uri
      : null;
}

/// Opens [url] in the browser if [safeExternalUri] allows it; returns
/// whether it did.
Future<bool> openExternalUrl(String url) async {
  final uri = safeExternalUri(url);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
