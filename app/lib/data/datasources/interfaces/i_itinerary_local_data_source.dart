import 'package:hive_ce/hive.dart';
import '../../models/itinerary_item.dart';

/// 行程項目 (ItineraryItemModel) 的本地資料來源介面
abstract interface class IItineraryLocalDataSource {
  /// 取得所有行程項目
  List<ItineraryItemModel> getAll();

  /// 根據行程 ID 取得項目
  List<ItineraryItemModel> getByTripId(String tripId);

  /// 透過 Key 取得單一行程項目
  ItineraryItemModel? getByKey(dynamic key);

  /// 透過 ID 取得單一行程項目 (UUID)
  ItineraryItemModel? getById(String id);

  /// 新增行程項目
  Future<void> add(ItineraryItemModel item);

  /// 更新行程項目
  Future<void> update(ItineraryItemModel item);

  /// 刪除行程項目
  Future<void> delete(dynamic key);

  /// 刪除行程項目 (透過 ID)
  Future<void> deleteById(String id);

  /// 清除指定行程的所有項目
  Future<void> clearByTripId(String tripId);

  /// 清除所有行程項目
  Future<void> clear();

  /// 監聽資料變更流
  Stream<BoxEvent> watch();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();
}
