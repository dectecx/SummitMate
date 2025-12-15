import 'package:isar/isar.dart';
import '../models/settings.dart';

/// Settings Repository
/// 管理全域設定的 CRUD 操作
class SettingsRepository {
  final Isar _isar;

  SettingsRepository(this._isar);

  /// 取得設定 (若不存在則建立預設值)
  Future<Settings> getSettings() async {
    final settings = await _isar.settings.get(1);
    if (settings != null) return settings;

    // 建立預設設定
    final defaultSettings = Settings.withDefaults();
    await _isar.writeTxn(() async {
      await _isar.settings.put(defaultSettings);
    });
    return defaultSettings;
  }

  /// 更新使用者名稱
  Future<void> updateUsername(String username) async {
    final settings = await getSettings();
    settings.username = username;
    await _isar.writeTxn(() async {
      await _isar.settings.put(settings);
    });
  }

  /// 更新最後同步時間
  Future<void> updateLastSyncTime(DateTime time) async {
    final settings = await getSettings();
    settings.lastSyncTime = time;
    await _isar.writeTxn(() async {
      await _isar.settings.put(settings);
    });
  }

  /// 監聽設定變更
  Stream<Settings?> watchSettings() {
    return _isar.settings.watchObject(1);
  }

  /// 重置設定 (Debug 用途)
  Future<void> resetSettings() async {
    await _isar.writeTxn(() async {
      await _isar.settings.clear();
    });
  }
}
