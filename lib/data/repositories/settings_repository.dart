import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../models/settings.dart';
import 'interfaces/i_settings_repository.dart';

/// Settings Repository
/// 管理全域設定的 CRUD 操作
class SettingsRepository implements ISettingsRepository {
  static const String _boxName = HiveBoxNames.settings;
  static const String _settingsKey = 'app_settings';

  Box<Settings>? _box;

  /// 開啟 Box
  @override
  Future<void> init() async {
    _box = await Hive.openBox<Settings>(_boxName);
  }

  /// 取得 Box
  Box<Settings> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('SettingsRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得設定 (若不存在則建立預設值)
  @override
  Settings getSettings() {
    var settings = box.get(_settingsKey);
    if (settings == null) {
      settings = Settings.withDefaults();
      box.put(_settingsKey, settings);
    }
    return settings;
  }

  /// 更新使用者名稱
  @override
  Future<void> updateUsername(String username) async {
    final settings = getSettings();
    settings.username = username;
    await settings.save();
  }

  /// 更新最後同步時間
  @override
  Future<void> updateLastSyncTime(DateTime? time) async {
    final settings = getSettings();
    settings.lastSyncTime = time;
    await settings.save();
  }

  /// 更新頭像
  @override
  Future<void> updateAvatar(String avatar) async {
    final settings = getSettings();
    settings.avatar = avatar;
    await settings.save();
  }

  /// 更新離線模式
  @override
  Future<void> updateOfflineMode(bool isOffline) async {
    final settings = getSettings();
    settings.isOfflineMode = isOffline;
    await settings.save();
  }

  /// 監聽設定變更
  @override
  Stream<BoxEvent> watchSettings() {
    return box.watch(key: _settingsKey);
  }

  /// 重置設定 (Debug 用途)
  @override
  Future<void> resetSettings() async {
    await box.clear();
  }
}
