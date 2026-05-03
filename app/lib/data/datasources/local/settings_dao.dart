import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/settings.dart';
import '../interfaces/i_settings_local_data_source.dart';
import '../../models/settings_table.dart';
import 'package:summitmate/core/theme.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [SettingsTable])
@LazySingleton(as: ISettingsLocalDataSource)
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin implements ISettingsLocalDataSource {
  SettingsDao(AppDatabase db) : super(db);

  @override
  Future<Settings?> getSettings() async {
    final query = select(settingsTable)..where((t) => t.id.equals(1));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return Settings(
      username: row.username,
      avatar: row.avatar,
      theme: AppThemeType.values[row.theme],
      isOfflineMode: row.isOfflineMode,
      enableNotifications: row.enableNotifications,
      language: row.language,
      darkMode: row.darkMode,
      lastSyncTime: row.lastSyncTime,
    );
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    await into(settingsTable).insertOnConflictUpdate(settings.toCompanion());
  }

  @override
  Future<void> clear() async {
    await delete(settingsTable).go();
  }
}
