import 'package:equatable/equatable.dart';
import '../../../data/models/download_task.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

abstract class OfflineMapState extends Equatable {
  const OfflineMapState();

  @override
  List<Object?> get props => [];
}

class OfflineMapInitial extends OfflineMapState {}

class OfflineMapLoaded extends OfflineMapState {
  final FMTCStore store;
  final bool isStoreReady;
  final List<DownloadTask> downloadQueue;
  final int tileCount;
  final double sizeMb;
  final bool isLoadingStats;
  final String packageName;

  /// 建構子
  ///
  /// [store] FMTC 圖磚儲存庫實例
  /// [isStoreReady] 儲存庫是否已就緒
  /// [downloadQueue] 下載任務佇列
  /// [tileCount] 已下載圖磚數量
  /// [sizeMb] 已佔用空間 (MB)
  /// [isLoadingStats] 是否正在讀取統計資訊
  /// [packageName] 地圖包名稱
  const OfflineMapLoaded({
    required this.store,
    this.isStoreReady = false,
    this.downloadQueue = const [],
    this.tileCount = 0,
    this.sizeMb = 0.0,
    this.isLoadingStats = false,
    this.packageName = '',
  });

  bool get isDownloading => downloadQueue.any((t) => t.status == TaskStatus.downloading);
  double get downloadProgress => downloadQueue.isNotEmpty ? downloadQueue.first.progress : 0.0;

  OfflineMapLoaded copyWith({
    FMTCStore? store,
    bool? isStoreReady,
    List<DownloadTask>? downloadQueue,
    int? tileCount,
    double? sizeMb,
    bool? isLoadingStats,
    String? packageName,
  }) {
    return OfflineMapLoaded(
      store: store ?? this.store,
      isStoreReady: isStoreReady ?? this.isStoreReady,
      downloadQueue: downloadQueue ?? this.downloadQueue,
      tileCount: tileCount ?? this.tileCount,
      sizeMb: sizeMb ?? this.sizeMb,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      packageName: packageName ?? this.packageName,
    );
  }

  @override
  List<Object?> get props => [store, isStoreReady, downloadQueue, tileCount, sizeMb, isLoadingStats, packageName];
}

class OfflineMapError extends OfflineMapState {
  final String message;

  const OfflineMapError(this.message);

  @override
  List<Object> get props => [message];
}
