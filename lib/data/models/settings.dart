import 'package:hive/hive.dart';

part 'settings.g.dart';

/// 全域設定
@HiveType(typeId: 0)
class Settings extends HiveObject {
  /// 使用者暱稱 (用於留言識別)
  @HiveField(0)
  String username;

  /// 上次同步時間
  @HiveField(1)
  DateTime? lastSyncTime;

  /// 使用者頭像 (Emoji)
  @HiveField(2)
  String avatar;

  /// 是否為離線模式
  @HiveField(3)
  bool isOfflineMode;

  Settings({
    this.username = '',
    this.lastSyncTime,
    this.avatar = '🐻', // 預設熊頭像
    this.isOfflineMode = false, // 預設連線模式
  });

  /// 建立預設設定
  factory Settings.withDefaults() {
    return Settings();
  }
}
