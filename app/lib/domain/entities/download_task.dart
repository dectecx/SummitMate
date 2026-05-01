import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_map/flutter_map.dart';

part 'download_task.freezed.dart';

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

/// 離線地圖下載任務實體 (Domain Entity)
@freezed
abstract class DownloadTask with _$DownloadTask {
  const factory DownloadTask({
    required String id,
    required String name,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    @Default(TaskStatus.pending) TaskStatus status,
    @Default(0.0) double progress,
    @Default(0) int successfulTiles,
    @Default(0) int failedTiles,
  }) = _DownloadTask;
}
