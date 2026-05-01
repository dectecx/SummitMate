import 'package:hive_ce/hive.dart';
import 'package:summitmate/core/theme.dart';
import '../../domain/entities/settings.dart';

part 'settings_model.g.dart';

/// 使用者設定持久化模型 (Persistence Model)
@HiveType(typeId: 0)
class SettingsModel extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String avatar;

  @HiveField(2)
  AppThemeType theme;

  @HiveField(3)
  bool isOfflineMode;

  @HiveField(4)
  bool enableNotifications;

  @HiveField(5)
  String language;

  @HiveField(6)
  bool darkMode;

  @HiveField(7)
  DateTime? lastSyncTime;

  SettingsModel({
    this.username = '',
    this.avatar = '🐻',
    this.theme = AppThemeType.nature,
    this.isOfflineMode = true,
    this.enableNotifications = true,
    this.language = 'zh',
    this.darkMode = false,
    this.lastSyncTime,
  });

  /// 轉換為 Domain Entity
  Settings toDomain() {
    return Settings(
      username: username,
      avatar: avatar,
      theme: theme,
      isOfflineMode: isOfflineMode,
      enableNotifications: enableNotifications,
      language: language,
      darkMode: darkMode,
      lastSyncTime: lastSyncTime,
    );
  }

  /// 從 Domain Entity 建立 Persistence Model
  factory SettingsModel.fromDomain(Settings entity) {
    return SettingsModel(
      username: entity.username,
      avatar: entity.avatar,
      theme: entity.theme,
      isOfflineMode: entity.isOfflineMode,
      enableNotifications: entity.enableNotifications,
      language: entity.language,
      darkMode: entity.darkMode,
      lastSyncTime: entity.lastSyncTime,
    );
  }
}
