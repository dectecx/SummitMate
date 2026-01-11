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
  ///
  /// [day] 行程天數 (e.g., "D1")
  List<ItineraryItem> getItemsByDay(String day);

  /// 取得單一行程節點
  ///
  /// [key] 行程節點 Key
  ItineraryItem? getItemByKey(dynamic key);

  /// 打卡 - 設定實際時間
  ///
  /// [key] 行程節點 Key
  /// [time] 打卡時間
  Future<void> checkIn(dynamic key, DateTime time);

  /// 清除打卡
  ///
  /// [key] 行程節點 Key
  Future<void> clearCheckIn(dynamic key);

  /// 批次覆寫行程 (從 Google Sheets 同步)
  ///
  /// [cloudItems] 雲端下載的行程節點列表
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems);

  /// 監聽行程變更
  Stream<BoxEvent> watchAllItems();

  /// 重置所有打卡紀錄
  Future<void> resetAllCheckIns();

  /// 新增行程節點
  ///
  /// [item] 欲新增的節點
  Future<void> addItem(ItineraryItem item);

  /// 更新行程節點
  ///
  /// [key] 目標節點 Key
  /// [item] 更新後的節點資料
  Future<void> updateItem(dynamic key, ItineraryItem item);

  /// 儲存最後同步時間
  ///
  /// [time] 同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  ///
  /// [tripId] 行程 ID
  Future<void> sync(String tripId);

  /// 刪除行程節點
  ///
  /// [key] 目標節點 Key
  Future<void> deleteItem(dynamic key);
}
