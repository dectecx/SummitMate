import 'package:hive/hive.dart';
import '../../models/itinerary_item.dart';

/// Itinerary Repository 抽象介面
/// 定義行程資料存取的契約
abstract interface class IItineraryRepository {
  /// 初始化
  Future<void> init();

  /// 取得所有行程節點
  List<ItineraryItem> getAllItems();

  /// 依天數取得行程節點
  List<ItineraryItem> getItemsByDay(String day);

  /// 取得單一行程節點
  ItineraryItem? getItemByKey(dynamic key);

  /// 打卡 - 設定實際時間
  Future<void> checkIn(dynamic key, DateTime time);

  /// 清除打卡
  Future<void> clearCheckIn(dynamic key);

  /// 批次覆寫行程 (從 Google Sheets 同步)
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems);

  /// 監聽行程變更
  Stream<BoxEvent> watchAllItems();

  /// 重置所有打卡紀錄
  Future<void> resetAllCheckIns();

  /// 新增行程節點
  Future<void> addItem(ItineraryItem item);

  /// 更新行程節點
  Future<void> updateItem(dynamic key, ItineraryItem item);

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  Future<void> sync(String tripId);

  /// 刪除行程節點
  Future<void> deleteItem(dynamic key);
}
