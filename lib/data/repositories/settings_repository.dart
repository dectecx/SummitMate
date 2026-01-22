import 'package:hive/hive.dart';
import 'package:summitmate/core/theme.dart';
import '../../core/error/result.dart';
import '../models/settings.dart';
import 'interfaces/i_settings_repository.dart';
import '../datasources/interfaces/i_settings_local_data_source.dart';
import '../../infrastructure/tools/log_service.dart';

/// 設定 Repository (支援 DataSource 模式)
///
/// 管理全域設定的 CRUD 操作。
/// 設定資料為應用程式層級，儲存於本地 Hive。
class SettingsRepository implements ISettingsRepository {
  static const String _source = 'SettingsRepository';

  final ISettingsLocalDataSource _localDataSource;

  /// 快取設定供同步讀取
  Settings? _cachedSettings;

  SettingsRepository({required ISettingsLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      // 預載設定到快取
      _cachedSettings = _localDataSource.getSettings();
      return const Success(null);
    } catch (e) {
      LogService.error('Init failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  // ========== Data Operations ==========

  @override
  Settings getSettings() {
    if (_cachedSettings == null) {
      _cachedSettings = _localDataSource.getSettings();
      if (_cachedSettings == null) {
        _cachedSettings = Settings.withDefaults();
        _localDataSource.saveSettings(_cachedSettings!);
      }
    }
    return _cachedSettings!;
  }

  @override
  Future<void> updateUsername(String username) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(username: username);
    await _localDataSource.saveSettings(newSettings);
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateLastSyncTime(DateTime? time) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(lastSyncTime: time);
    await _localDataSource.saveSettings(newSettings);
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateAvatar(String avatar) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(avatar: avatar);
    await _localDataSource.saveSettings(newSettings);
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateOfflineMode(bool isOffline) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(isOfflineMode: isOffline);
    await _localDataSource.saveSettings(newSettings);
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateTheme(AppThemeType theme) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(theme: theme);
    await _localDataSource.saveSettings(newSettings);
    _cachedSettings = newSettings;
  }

  @override
  Future<void> resetSettings() async {
    await _localDataSource.clear();
    _cachedSettings = null;
  }

  // ========== Watch ==========

  @override
  Stream<BoxEvent> watchSettings() {
    // Note: Internal implementation may need adjustment based on DataSource
    // For now, return empty stream as this requires Hive Box access
    return const Stream.empty();
  }
}
