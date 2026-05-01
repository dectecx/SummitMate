import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:summitmate/core/theme.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

/// 使用者設定領域實體 (Domain Entity)
@freezed
abstract class Settings with _$Settings {
  const Settings._();

  const factory Settings({
    @Default('') String username,
    @Default('🐻') String avatar,
    @Default(AppThemeType.nature) AppThemeType theme,
    @Default(true) bool isOfflineMode,
    @Default(true) bool enableNotifications,
    @Default('zh') String language,
    @Default(false) bool darkMode,
    DateTime? lastSyncTime,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
}
