import '../../models/settings.dart';

/// 設定本地資料來源介面
///
/// 負責定義對本地資料庫 (Hive) 的設定存取操作。
/// 設定資料為應用程式層級，與使用者綁定。
abstract class ISettingsLocalDataSource {
  /// 初始化資料來源
  ///
  /// 開啟 Hive Box，需在使用其他方法前呼叫。
  Future<void> init();

  /// 取得設定
  ///
  /// 回傳: 設定物件，若不存在則回傳 null
  Settings? getSettings();

  /// 儲存設定
  ///
  /// [settings] 欲儲存的設定物件
  Future<void> saveSettings(Settings settings);

  /// 清除設定
  ///
  /// 用於登出或重置情境，會移除所有設定資料。
  Future<void> clear();
}
