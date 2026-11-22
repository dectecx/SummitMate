import 'dart:async';

import 'package:background_downloader/background_downloader.dart';

/// `FileDownloader().updates` is a single-subscription stream: a second `listen` (for the next download in the same
/// session) throws "Stream has already been listened to". Everything that needs task updates listens here instead.
abstract final class DownloadUpdates {
  static final Stream<TaskUpdate> stream = _start();

  static Stream<TaskUpdate> _start() {
    final c = StreamController<TaskUpdate>.broadcast();
    FileDownloader().updates.listen(c.add);
    return c.stream;
  }
}
