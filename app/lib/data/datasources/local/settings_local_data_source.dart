import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import '../../models/settings_model.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_settings_local_data_source.dart';

/// 設定本地資料來源實作 (Hive)
@LazySingleton(as: ISettingsLocalDataSource)
class SettingsLocalDataSource implements ISettingsLocalDataSource {
  static const String _settingsKey = 'app_settings';

  final Box<SettingsModel> _box;

  SettingsLocalDataSource({required HiveService hiveService})
    : _box = hiveService.getBox<SettingsModel>(HiveBoxNames.settings);

  Box<SettingsModel> get _settings {
    if (!_box.isOpen) {
      throw StateError('SettingsLocalDataSource not initialized. Call init() first.');
    }
    return _box;
  }

  @override
  SettingsModel? getSettings() => _settings.get(_settingsKey);

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _settings.put(_settingsKey, settings);
  }

  @override
  Future<void> clear() async {
    await _settings.clear();
  }
}
