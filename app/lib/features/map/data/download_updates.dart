import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/widgets.dart';

/// `FileDownloader().updates` is a single-subscription stream: a second `listen` (for the next download in the same
/// session) throws "Stream has already been listened to". Everything that needs task updates listens here instead.
abstract final class DownloadUpdates {
  static final Stream<TaskUpdate> stream = _start();

  static Stream<TaskUpdate> _start() {
    final c = StreamController<TaskUpdate>.broadcast();
    FileDownloader().updates.listen(c.add);
    return c.stream;
  }

  /// Call once at startup: processes what happened while the app was suspended, now and every time it comes back.
  static Future<void> resumeFromBackground() async {
    await FileDownloader().resumeFromBackground();
    WidgetsBinding.instance.addObserver(_ResumeHook());
  }
}

class _ResumeHook with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) FileDownloader().resumeFromBackground();
  }
}
