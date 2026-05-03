import 'package:summitmate/core/theme.dart';
import '../entities/settings.dart';

/// 設定資料存取的 Repository 介面
///
/// 負責本地設定的讀取與儲存。
abstract interface class ISettingsRepository {
  // ========== Data Operations ==========

  /// 取得設定（若不存在則建立預設值）
  Future<Settings> getSettings();

  /// 更新使用者名稱
  ///
  /// [username] 新的使用者名稱
  Future<void> updateUsername(String username);

  /// 更新最後同步時間
  ///
  /// [time] 同步時間，null 表示重置
  Future<void> updateLastSyncTime(DateTime? time);

  /// 更新頭像
  ///
  /// [avatar] 新的頭像識別字串
  Future<void> updateAvatar(String avatar);

  /// 更新離線模式
  ///
  /// [isOffline] 是否為離線模式
  Future<void> updateOfflineMode(bool isOffline);

  /// 更新主題
  ///
  /// [theme] 新的主題類型
  Future<void> updateTheme(AppThemeType theme);

  /// 重置設定為預設值
  Future<void> resetSettings();

  // ========== Watch ==========

  /// 監聽設定變更的串流
  Stream<void> watchSettings();
}
