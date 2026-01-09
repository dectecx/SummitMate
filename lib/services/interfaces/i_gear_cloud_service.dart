import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/meal_item.dart';

/// 雲端裝備操作結果
class GearCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const GearCloudResult._({required this.isSuccess, this.data, this.errorMessage});

  factory GearCloudResult.success(T data) => GearCloudResult._(isSuccess: true, data: data);
  factory GearCloudResult.failure(String message) => GearCloudResult._(isSuccess: false, errorMessage: message);
}

/// 雲端裝備庫服務介面
/// 負責裝備組合的上傳、下載、分享
abstract interface class IGearCloudService {
  /// 取得公開/保護的裝備組合列表
  Future<GearCloudResult<List<GearSet>>> getGearSets();

  /// 用 Key 取得特定裝備組合 (含 items)
  Future<GearCloudResult<GearSet>> getGearSetByKey(String key);

  /// 下載指定裝備組合
  Future<GearCloudResult<GearSet>> downloadGearSet(String uuid, {String? key});

  /// 上傳裝備組合
  Future<GearCloudResult<GearSet>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  });

  /// 刪除裝備組合 (需要 Key 驗證)
  Future<GearCloudResult<bool>> deleteGearSet(String uuid, String key);
}
