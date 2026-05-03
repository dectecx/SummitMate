import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/settings.dart';
import '../../core/theme.dart';

/// 使用者設定資料表
class SettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant('🐻'))();

  IntColumn get theme => integer().withDefault(const Constant(0))();

  BoolColumn get isOfflineMode => boolean().withDefault(const Constant(true))();
  BoolColumn get enableNotifications => boolean().withDefault(const Constant(true))();
  TextColumn get language => text().withDefault(const Constant('zh'))();
  BoolColumn get darkMode => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
}

/// 設定資料對映擴充
extension SettingsMapping on Settings {
  SettingsTableCompanion toCompanion() {
    return SettingsTableCompanion.insert(
      id: const Value(1),
      username: Value(username),
      avatar: Value(avatar),
      theme: Value(theme.index),
      isOfflineMode: Value(isOfflineMode),
      enableNotifications: Value(enableNotifications),
      language: Value(language),
      darkMode: Value(darkMode),
      lastSyncTime: Value(lastSyncTime),
    );
  }
}
