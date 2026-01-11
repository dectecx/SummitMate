import 'package:hive/hive.dart';
import '../../models/settings.dart';

/// Settings Repository 抽象介面
/// 定義設定資料存取的契約
abstract interface class ISettingsRepository {
  /// 初始化 Repository
  Future<void> init();

  /// 取得設定 (若不存在則建立預設值)
  Settings getSettings();

  /// 更新使用者名稱
  ///
  /// [username] 新的使用者名稱
  Future<void> updateUsername(String username);

  /// 更新最後同步時間
  ///
  /// [time] 最後同步時間
  Future<void> updateLastSyncTime(DateTime? time);

  /// 更新頭像
  ///
  /// [avatar] 新的頭像 (e.g., Emoji 字串)
  Future<void> updateAvatar(String avatar);

  /// 更新離線模式
  ///
  /// [isOffline] 是否開啟離線模式
  Future<void> updateOfflineMode(bool isOffline);

  /// 監聽設定變更
  Stream<BoxEvent> watchSettings();

  /// 重置設定
  Future<void> resetSettings();
}
