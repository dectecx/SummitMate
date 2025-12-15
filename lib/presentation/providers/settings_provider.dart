import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/settings.dart';

/// 設定狀態管理
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;
  final SharedPreferences _prefs;

  Settings? _settings;
  bool _isLoading = true;
  String? _error;

  SettingsProvider()
      : _repository = getIt<SettingsRepository>(),
        _prefs = getIt<SharedPreferences>() {
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

  /// 是否已設定使用者名稱 (用於 Onboarding 判斷)
  bool get hasUsername => username.isNotEmpty;

  /// 上次同步時間
  DateTime? get lastSyncTime => _settings?.lastSyncTime;

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
      await _repository.updateUsername(username);
      await _prefs.setString(PrefKeys.username, username);
      _settings = _repository.getSettings();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新同步時間
  Future<void> updateLastSyncTime(DateTime time) async {
    try {
      await _repository.updateLastSyncTime(time);
      _settings = _repository.getSettings();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重新載入設定
  void reload() {
    _loadSettings();
  }
}
