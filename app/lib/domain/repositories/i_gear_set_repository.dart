import '../../core/error/result.dart';
import '../entities/gear_item.dart';
import '../domain.dart';

/// 裝備組合 (GearSet) Repository 介面
///
/// 負責管理「官方裝備清單」或「已分享清單」的存取（本地 & 雲端）。
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
  /// [id] 本地識別碼（可選）
  /// [key] 雲端識別碼
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key});

  /// 上傳裝備組合（建立分享連結）
  ///
  /// [tripId] 關聯行程 ID
  /// [title] 清單標題
  /// [author] 作者名稱
  /// [visibility] 可見度
  /// [items] 裝備項目列表（Domain Entity）
  /// [meals] 餐食計畫（可選）
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

  /// 刪除雲端裝備組合
  ///
  /// [id] 本地識別碼 (若有)
  /// [key] 雲端識別碼
  Future<Result<bool, Exception>> deleteGearSet(String id, String key);

  // === 本地紀錄 (Local Key Tracking) ===

  /// 取得本地已上傳過的 Key 紀錄列表
  Future<List<GearKeyRecord>> getUploadedKeys();

  /// 儲存一條上傳紀錄
  Future<void> saveUploadedKey(String key, String title, String visibility);

  /// 移除一條上傳紀錄
  Future<void> removeUploadedKey(String key);
}
