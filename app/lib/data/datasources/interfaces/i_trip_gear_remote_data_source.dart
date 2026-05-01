import '../../../domain/entities/gear_item.dart';
import '../../models/gear_item.dart';

/// 行程裝備 (Trip Gear) 的遠端資料來源介面
///
/// 負責與遠端伺服器通訊，並回傳 [GearItemModel] 資料模型。
abstract interface class ITripGearRemoteDataSource {
  /// 取得行程裝備清單
  ///
  /// [tripId] 行程 ID
  Future<List<GearItemModel>> getTripGear(String tripId);

  /// 新增裝備至行程
  ///
  /// [tripId] 行程 ID
  /// [item] 欲新增的裝備實體
  Future<GearItemModel> addTripGear(String tripId, GearItem item);

  /// 更新行程裝備內容
  ///
  /// [tripId] 行程 ID
  /// [item] 欲更新的裝備實體（需含 id）
  Future<GearItemModel> updateTripGear(String tripId, GearItem item);

  /// 從行程中刪除裝備
  ///
  /// [tripId] 行程 ID
  /// [itemId] 裝備 ID
  Future<void> deleteTripGear(String tripId, String itemId);

  /// 批量替換行程所有裝備（離線同步用）
  ///
  /// [tripId] 行程 ID
  /// [items] 新的完整裝備清單實體
  Future<void> replaceAllTripGear(String tripId, List<GearItem> items);
}
