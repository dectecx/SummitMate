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

  Settings({
    this.username = '',
    this.lastSyncTime,
  });

  /// 建立預設設定
  factory Settings.withDefaults() {
    return Settings();
  }
}
