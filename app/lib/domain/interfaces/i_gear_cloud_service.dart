import '../../core/error/result.dart';
import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/meal_item.dart';

/// 雲端裝備庫服務介面
/// 負責裝備組合的上傳、下載、分享
abstract interface class IGearCloudService {
  /// 取得公開/保護的裝備組合列表
  Future<Result<List<GearSet>, Exception>> getGearSets();

  /// 用 Key 取得特定裝備組合 (含 items)
  ///
  /// [key] 4位數分享碼
  Future<Result<GearSet, Exception>> getGearSetByKey(String key);

  /// 下載指定裝備組合
  ///
  /// [id] 裝備組合 ID
  /// [key] 如果是受保護的組合，需要提供 Key
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key});

  /// 上傳裝備組合
  ///
  /// [tripId] 關聯的行程 ID
  /// [title] 裝備組合標題
  /// [author] 作者名稱
  /// [visibility] 可見度 (Public/Protected/Private)
  /// [items] 裝備項目列表
  /// [meals] 糧食計畫列表 (可選)
  /// [key] 設定的分享碼 (若 visibility 非 Public 則必填)
  Future<Result<GearSet, Exception>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  });

  /// 刪除裝備組合 (需要 Key 驗證)
  ///
  /// [id] 裝備組合 ID
  /// [key] 驗證用的分享碼
  Future<Result<bool, Exception>> deleteGearSet(String id, String key);
}
