import 'package:injectable/injectable.dart';
import '../../../core/core.dart';
import '../../../domain/domain.dart';
import '../../models/gear_item_model.dart';
import '../../models/gear_set.dart';
import '../../models/meal_item.dart';
/// 模擬雲端裝備庫服務 (與 IGearCloudService 介面一致)
/// 用於在遠端實作尚未完成或環境限制時，確保系統不崩潰。
@LazySingleton(as: IGearCloudService)
class FakeGearCloudService implements IGearCloudService {
  @override
  Future<Result<List<GearSet>, Exception>> getGearSets() async {
    // 模擬回傳空列表，避免 UI 完全抓不到資料崩潰
    return const Success([]);
  }

  @override
  Future<Result<GearSet, Exception>> getGearSetByKey(String key) async {
    return Failure(Exception('尚未實作或找不到 Key: $key'));
  }

  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key}) async {
    return Failure(Exception('模擬環境不支援下載'));
  }

  @override
  Future<Result<bool, Exception>> deleteGearSet(String id, String key) async {
    return const Success(true);
  }

  @override
  Future<Result<GearSet, Exception>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  }) async {
    // 模擬上傳成功，將 Entity 轉換為 Model 以存入 GearSet
    final itemModels = items.map((e) => GearItemModel.fromDomain(e)).toList();

    final mockSet = GearSet(
      id: 'fake-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      author: author,
      totalWeight: items.fold(0.0, (sum, i) => sum + i.totalWeight),
      itemCount: items.length,
      visibility: visibility,
      items: itemModels,
      meals: meals,
      createdAt: DateTime.now(),
      createdBy: author,
      uploadedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: author,
    );
    return Success(mockSet);
  }
}
