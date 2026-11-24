import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web address in the phone's own browser (not an in-app web view).
/// Returns false when nothing could open it. Tests override this provider.
typedef LinkOpener = Future<bool> Function(Uri url);

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => (url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);
