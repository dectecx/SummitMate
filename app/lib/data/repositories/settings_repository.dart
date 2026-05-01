import 'package:injectable/injectable.dart';
import 'package:summitmate/core/theme.dart';
import '../models/settings_model.dart';
import 'package:summitmate/domain/domain.dart';
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

  SettingsRepository({required ISettingsLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  // ========== Data Operations ==========

  @override
  Settings getSettings() {
    if (_cachedSettings == null) {
      final model = _localDataSource.getSettings();
      if (model == null) {
        _cachedSettings = const Settings();
        _localDataSource.saveSettings(SettingsModel.fromDomain(_cachedSettings!));
      } else {
        _cachedSettings = model.toDomain();
      }
    }
    return _cachedSettings!;
  }

  @override
  Future<void> updateUsername(String username) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(username: username);
    await _localDataSource.saveSettings(SettingsModel.fromDomain(newSettings));
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateLastSyncTime(DateTime? time) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(lastSyncTime: time);
    await _localDataSource.saveSettings(SettingsModel.fromDomain(newSettings));
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateAvatar(String avatar) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(avatar: avatar);
    await _localDataSource.saveSettings(SettingsModel.fromDomain(newSettings));
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateOfflineMode(bool isOffline) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(isOfflineMode: isOffline);
    await _localDataSource.saveSettings(SettingsModel.fromDomain(newSettings));
    _cachedSettings = newSettings;
  }

  @override
  Future<void> updateTheme(AppThemeType theme) async {
    final settings = getSettings();
    final newSettings = settings.copyWith(theme: theme);
    await _localDataSource.saveSettings(SettingsModel.fromDomain(newSettings));
    _cachedSettings = newSettings;
  }

  @override
  Future<void> resetSettings() async {
    await _localDataSource.clear();
    _cachedSettings = null;
  }

  // ========== Watch ==========

  @override
  Stream<void> watchSettings() {
    // Note: Internal implementation could use a stream controller if needed
    return const Stream.empty();
  }
}
