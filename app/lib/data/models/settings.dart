import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:summitmate/core/theme.dart';

part 'settings.g.dart';

/// 全域設定
@HiveType(typeId: 0)
@JsonSerializable(fieldRename: FieldRename.snake)
class Settings extends HiveObject {
  /// 使用者暱稱 (用於留言識別)
  @HiveField(0, defaultValue: '')
  @JsonKey(defaultValue: '')
  String username;

  /// 上次同步時間
  @HiveField(1)
  DateTime? lastSyncTime;

  /// 使用者頭像 (Emoji)
  @HiveField(2, defaultValue: '🐻')
  @JsonKey(defaultValue: '🐻')
  String avatar;

  /// 是否為離線模式
  @HiveField(3, defaultValue: false)
  @JsonKey(defaultValue: false)
  bool isOfflineMode;

  /// App 主題
  @HiveField(4, defaultValue: AppThemeType.nature)
  @JsonKey(defaultValue: AppThemeType.nature)
  AppThemeType theme;

  Settings({
    this.username = '',
    this.lastSyncTime,
    this.avatar = '🐻', // 預設熊頭像
    this.isOfflineMode = false, // 預設連線模式
    this.theme = AppThemeType.nature, // 預設自然山林
  });

  /// 建立預設設定
  factory Settings.withDefaults() {
    return Settings();
  }

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  Settings copyWith({
    String? username,
    DateTime? lastSyncTime,
    String? avatar,
    bool? isOfflineMode,
    AppThemeType? theme,
  }) {
    return Settings(
      username: username ?? this.username,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      avatar: avatar ?? this.avatar,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      theme: theme ?? this.theme,
    );
  }
}
