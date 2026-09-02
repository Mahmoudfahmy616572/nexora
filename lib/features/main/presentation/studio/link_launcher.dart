import 'package:url_launcher/url_launcher.dart';

/// Opens an external URL. Used for tappable links inside the CV preview.
class LinkLauncher {
  const LinkLauncher._();

  static Future<bool> open(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
