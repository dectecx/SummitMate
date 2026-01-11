import '../../models/gear_key_record.dart';

/// 上傳裝備清單 Key 的本地資料來源介面
///
/// 負責儲存與管理已上傳至雲端的裝備清單 Key 記錄，方便後續查詢或分享。
abstract class IGearKeyLocalDataSource {
  /// 取得所有已上傳的 Key 記錄
  Future<List<GearKeyRecord>> getUploadedKeys();

  /// 儲存一筆上傳 Key 記錄
  ///
  /// [key] 雲端回傳的唯一識別碼
  /// [title] 清單標題
  /// [visibility] 可見度 (public / private)
  Future<void> saveUploadedKey(String key, String title, String visibility);

  /// 移除一筆上傳 Key 記錄
  Future<void> removeUploadedKey(String key);
}
