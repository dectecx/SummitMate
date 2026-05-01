import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import 'package:summitmate/core/theme.dart';
import '../models/settings.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../datasources/interfaces/i_settings_local_data_source.dart';

/// 設定 Repository (支援 DataSource 模式)
///
/// 管理全域設定的 CRUD 操作。
/// 設定資料為應用程式層級，儲存於本地 Hive。
@LazySingleton(as: ISettingsRepository)
class SettingsRepository implements ISettingsRepository {
  final ISettingsLocalDataSource _localDataSource;

  /// 快取設定供同步讀取
  Settings? _cachedSettings;

  SettingsRepository({required ISettingsLocalDataSource localDataSource}) : _localDataSource = localDataSource {
    // 預載設定到快取
    _cachedSettings = _localDataSource.getSettings();
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
