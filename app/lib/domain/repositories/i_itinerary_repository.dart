import '../../domain/entities/itinerary_item.dart';
import '../../../core/error/result.dart';

/// 行程節點 Repository 抽象介面
abstract interface class IItineraryRepository {
  /// 初始化
  Future<Result<void, Exception>> init();

  /// 取得指定行程的所有節點
  List<ItineraryItem> getByTripId(String tripId);

  /// 取得特定 ID 的節點
  ItineraryItem? getById(String id);

  /// 新增節點
  Future<Result<void, Exception>> add(ItineraryItem item);

  /// 更新節點
  Future<Result<void, Exception>> update(ItineraryItem item);

  /// 刪除節點
  Future<Result<void, Exception>> delete(String id);

  /// 清除行程所有節點
  Future<Result<void, Exception>> clearByTripId(String tripId);

  /// 批量儲存節點 (通常用於同步)
  Future<Result<void, Exception>> saveAll(List<ItineraryItem> items);

  /// 切換打卡狀態
  Future<Result<void, Exception>> toggleCheckIn(String id);

  /// 觸發同步 (Fetch & Update)
  Future<Result<void, Exception>> sync(String tripId);
}
