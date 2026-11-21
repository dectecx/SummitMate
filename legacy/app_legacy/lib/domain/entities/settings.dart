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
    @Default(false) bool isOfflineMode,
    @Default(true) bool enableNotifications,
    @Default('zh') String language,
    @Default(false) bool darkMode,
    DateTime? lastSyncTime,
    // 自動同步間隔 (分鐘)
    // 0 = 關閉自動同步
    // 5~10080 (5分鐘~7天) = 使用者可選範圍
    // DevTools 模式下可設定 1~10080
    @Default(5) int autoSyncIntervalMinutes,
    @Default(15.0) double comfortWeightKg,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
}
