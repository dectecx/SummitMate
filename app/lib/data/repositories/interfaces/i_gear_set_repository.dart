import '../../../core/error/result.dart';
import '../../models/gear_set.dart';
import '../../models/gear_key_record.dart';
import '../../models/gear_item.dart';
import '../../models/meal_item.dart';

/// 裝備組合 (GearSet) Repository 介面
///
/// 負責管理「官方裝備清單」或「已分享清單」的存取 (Local & Cloud)。
abstract class IGearSetRepository {
  // === 遠端操作 (Remote Actions) ===

  /// 取得所有公開的裝備組合清單
  Future<Result<List<GearSet>, Exception>> getGearSets();

  /// 透過 Key 取得特定裝備組合
  ///
  /// [key] 裝備組合的唯一識別碼
  Future<Result<GearSet, Exception>> getGearSetByKey(String key);

  /// 下載特定裝備組合
  ///
  /// [uuid] 本地識別碼 (可選)
  /// [key] 雲端識別碼
  Future<Result<GearSet, Exception>> downloadGearSet(String uuid, {String? key});

  /// 上傳裝備組合 (建立分享連結)
  ///
  /// [tripId] 關聯行程 ID
  /// [title] 清單標題
  /// [author] 作者名稱
  /// [visibility] 可見度
  /// [items] 裝備項目列表
  /// [meals] 餐食計畫 (可選)
  /// [key] 若為更新舊有清單，則提供此 Key
  Future<Result<GearSet, Exception>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  });

  /// 刪除雲端上的裝備組合
  ///
  /// [uuid] 本地識別碼 (若有)
  /// [key] 雲端識別碼
  Future<Result<bool, Exception>> deleteGearSet(String uuid, String key);

  // === 本地金鑰儲存 (Local Key Storage) ===

  /// 取得本地已儲存的上傳記錄 (Key List)
  Future<List<GearKeyRecord>> getUploadedKeys();

  /// 儲存一筆上傳記錄 (Key) 到本地
  ///
  /// [key] 雲端識別碼
  /// [title] 標題
  /// [visibility] 可見度
  Future<void> saveUploadedKey(String key, String title, String visibility);

  /// 移除本地的上傳記錄
  ///
  /// [key] 雲端識別碼
  Future<void> removeUploadedKey(String key);
}
