import 'package:hive_ce/hive.dart';

part 'sync_status.g.dart';

/// 資料同步狀態
@HiveType(typeId: 20)
enum SyncStatus {
  /// 已同步
  @HiveField(0)
  synced,

  /// 等待建立 (本地新增)
  @HiveField(1)
  pendingCreate,

  /// 等待更新 (本地修改)
  @HiveField(2)
  pendingUpdate,

  /// 等待刪除 (本地刪除)
  @HiveField(3)
  pendingDelete,

  /// 同步錯誤
  @HiveField(4)
  error,
}
