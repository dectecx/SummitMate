import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/meal_item.dart';

/// 雲端裝備操作結果
class GearCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const GearCloudResult._({required this.isSuccess, this.data, this.errorMessage});

  /// 建立成功結果
  ///
  /// [data] 成功回傳的資料
  factory GearCloudResult.success(T data) => GearCloudResult._(isSuccess: true, data: data);

  /// 建立失敗結果
  ///
  /// [message] 錯誤訊息
  factory GearCloudResult.failure(String message) => GearCloudResult._(isSuccess: false, errorMessage: message);
}

/// 雲端裝備庫服務介面
/// 負責裝備組合的上傳、下載、分享
abstract interface class IGearCloudService {
  /// 取得公開/保護的裝備組合列表
  Future<GearCloudResult<List<GearSet>>> getGearSets();

  /// 用 Key 取得特定裝備組合 (含 items)
  ///
  /// [key] 4位數分享碼
  Future<GearCloudResult<GearSet>> getGearSetByKey(String key);

  /// 下載指定裝備組合
  ///
  /// [id] 裝備組合 ID
  /// [key] 如果是受保護的組合，需要提供 Key
  Future<GearCloudResult<GearSet>> downloadGearSet(String id, {String? key});

  /// 上傳裝備組合
  ///
  /// [tripId] 關聯的行程 ID
  /// [title] 裝備組合標題
  /// [author] 作者名稱
  /// [visibility] 可見度 (Public/Protected/Private)
  /// [items] 裝備項目列表
  /// [meals] 糧食計畫列表 (可選)
  /// [key] 設定的分享碼 (若 visibility 非 Public 則必填)
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
  ///
  /// [id] 裝備組合 ID
  /// [key] 驗證用的分享碼
  Future<GearCloudResult<bool>> deleteGearSet(String id, String key);
}
