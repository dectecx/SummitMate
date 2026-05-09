import '../../../core/error/result.dart';
import '../../../domain/domain.dart';

/// 雲端裝備庫遠端資料來源介面
/// 負責裝備組合的上傳、下載、分享
abstract interface class IGearCloudRemoteDataSource {
  /// 取得公開/保護的裝備組合列表
  Future<Result<List<GearSet>, Exception>> getGearSets({bool? myUploadedOnly});

  /// 下載指定裝備組合
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

  /// 刪除裝備組合
  ///
  /// [id] 裝備組合 ID
  Future<Result<bool, Exception>> deleteGearSet(String id);
}
