import '../../core/error/result.dart';
import '../entities/gear_item.dart';
import '../domain.dart';

/// 裝備組合 (GearSet) Repository 介面
///
/// 負責管理「官方裝備清單」或「已分享清單」的存取（本地 & 雲端）。
abstract class IGearSetRepository {
  // === 遠端操作 (Remote Actions) ===

  /// 取得雲端裝備組合清單 (支援過濾我上傳的)
  Future<Result<List<GearSet>, Exception>> getGearSets({bool? myUploadedOnly});

  /// 下載特定裝備組合
  ///
  /// [id] 裝備組合 ID
  /// [key] 如果是受保護的組合，需要提供 Key
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key});

  /// 上傳裝備組合
  Future<Result<GearSet, Exception>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  });

  /// 更新裝備組合
  Future<Result<GearSet, Exception>> updateGearSet({
    required String id,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  });

  /// 刪除雲端裝備組合
  Future<Result<bool, Exception>> deleteGearSet(String id);

  // === 本地紀錄 (Local Key Tracking) ===

  /// 取得本地已上傳過的 Key 紀錄列表
  Future<List<GearKeyRecord>> getUploadedKeys();

  /// 儲存一條上傳紀錄
  Future<void> saveUploadedKey(String key, String title, String visibility);

  /// 移除一條上傳紀錄
  Future<void> removeUploadedKey(String key);
}
