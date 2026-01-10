import 'dart:async';
import 'package:flutter_map/flutter_map.dart';

enum TaskStatus { pending, downloading, paused, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String name;
  final LatLngBounds bounds;
  final int minZoom;
  final int maxZoom;
  TaskStatus status;
  double progress;
  int successfulTiles;
  int failedTiles;
  StreamSubscription? subscription; // Generic stream subscription

  DownloadTask({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    this.status = TaskStatus.pending,
    this.progress = 0.0,
    this.successfulTiles = 0,
    this.failedTiles = 0,
    this.subscription,
  });
}
