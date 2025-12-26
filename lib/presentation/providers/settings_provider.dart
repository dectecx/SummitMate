import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/repositories/interfaces/i_settings_repository.dart';
import '../../data/models/settings.dart';
import '../../services/log_service.dart';

/// 設定狀態管理
class SettingsProvider extends ChangeNotifier {
  final ISettingsRepository _repository;
  final SharedPreferences _prefs;

  Settings? _settings;
  bool _isLoading = true;
  String? _error;

  SettingsProvider({ISettingsRepository? repository})
    : _repository = repository ?? getIt<ISettingsRepository>(),
      _prefs = getIt<SharedPreferences>() {
    LogService.info('SettingsProvider 初始化', source: 'Settings');
    _loadSettings();
  }

  /// 當前設定
  Settings? get settings => _settings;

  /// 使用者名稱
  String get username => _settings?.username ?? '';

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 錯誤訊息
  String? get error => _error;

  /// 是否已完成教學導覽 (預設為 false)
  bool get hasSeenOnboarding => _prefs.getBool('has_seen_onboarding') ?? false;

  /// 標記已完成教學導覽
  Future<void> completeOnboarding() async {
    await _prefs.setBool('has_seen_onboarding', true);
    notifyListeners();
  }

  /// 重置教學導覽 (用於重看)
  Future<void> resetOnboarding() async {
    await _prefs.setBool('has_seen_onboarding', false);
    notifyListeners();
  }

  /// 是否已設定使用者名稱 (用於 Onboarding 判斷)
  bool get hasUsername => username.isNotEmpty;

  /// 上次同步時間
  DateTime? get lastSyncTime => _settings?.lastSyncTime;

  /// 上次同步時間 (格式化顯示)
  String? get lastSyncTimeFormatted {
    final time = lastSyncTime?.toLocal(); // 轉換為本地時區
    if (time == null) return null;
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 使用者頭像
  String get avatar => _settings?.avatar ?? '🐻';

  /// 是否為離線模式
  bool get isOfflineMode => _settings?.isOfflineMode ?? false;

  /// 設定使用者名稱 (別名)
  Future<void> setUsername(String username) => updateUsername(username);

  /// 載入設定
  void _loadSettings() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _settings = _repository.getSettings();

      // 也嘗試從 SharedPreferences 讀取 (向下相容)
      if (_settings?.username.isEmpty ?? true) {
        final savedUsername = _prefs.getString(PrefKeys.username);
        if (savedUsername != null && savedUsername.isNotEmpty) {
          updateUsername(savedUsername);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新使用者名稱
  Future<void> updateUsername(String username) async {
    try {
      LogService.info('更新暱稱: $username', source: 'Settings');
      await _repository.updateUsername(username);
      await _prefs.setString(PrefKeys.username, username);
      _settings = _repository.getSettings();
      _error = null;
      notifyListeners();
    } catch (e) {
      LogService.error('更新暱稱失敗: $e', source: 'Settings');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新同步時間
  Future<void> updateLastSyncTime(DateTime? time) async {
    try {
      await _repository.updateLastSyncTime(time);
      _settings = _repository.getSettings();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 設定頭像
  Future<void> setAvatar(String avatar) async {
    try {
      await _repository.updateAvatar(avatar);
      _settings = _repository.getSettings();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 切換離線模式
  Future<void> toggleOfflineMode() async {
    await setOfflineMode(!isOfflineMode);
  }

  /// 設定離線模式
  Future<void> setOfflineMode(bool isOffline) async {
    try {
      await _repository.updateOfflineMode(isOffline);
      _settings = _repository.getSettings();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重設身分 (登出) - 同時清除設定資料
  Future<void> resetIdentity() async {
    try {
      LogService.info('重設使用者身分 (登出)', source: 'Settings');

      // 清除 Hive settings box
      final settingsBox = await Hive.openBox<Settings>(HiveBoxNames.settings);
      await settingsBox.clear();

      // 清除 SharedPreferences 中的暱稱
      await _prefs.remove(PrefKeys.username);

      // 重新載入預設值
      _loadSettings();
    } catch (e) {
      LogService.error('重設身分失敗: $e', source: 'Settings');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重新載入設定
  void reload() {
    _loadSettings();
  }
}
