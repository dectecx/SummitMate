import 'dart:async';
import 'package:flutter_map/flutter_map.dart';

/// 下載任務狀態
enum TaskStatus {
  /// 等待中
  pending,

  /// 下載中
  downloading,

  /// 已暫停
  paused,

  /// 已完成
  completed,

  /// 失敗
  failed,

  /// 已取消
  cancelled,
}

/// 離線地圖下載任務
class DownloadTask {
  /// 任務 ID (UUID)
  final String id;

  /// 區塊名稱 (Region ID)
  final String name;

  /// 地圖邊界
  final LatLngBounds bounds;

  /// 最小縮放層級
  final int minZoom;

  /// 最大縮放層級
  final int maxZoom;

  /// 當前狀態
  TaskStatus status;

  /// 下載進度 (0.0 - 1.0)
  double progress;

  /// 成功下載圖磚數
  int successfulTiles;

  /// 失敗圖磚數
  int failedTiles;

  /// 串流訂閱 (Generic stream subscription)
  StreamSubscription? subscription;

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
