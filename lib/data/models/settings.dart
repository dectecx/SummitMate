import 'package:isar/isar.dart';

part 'settings.g.dart';

/// 全域設定 Collection
/// 用於儲存使用者暱稱與同步時間
@collection
class Settings {
  /// Isar ID - 固定為 1 (單例模式)
  Id? id;

  /// 使用者暱稱 (用於留言識別)
  String username = '';

  /// 上次同步時間
  DateTime? lastSyncTime;

  /// 建構子
  Settings();

  /// 建立預設設定
  factory Settings.withDefaults() {
    return Settings()..id = 1;
  }
}
