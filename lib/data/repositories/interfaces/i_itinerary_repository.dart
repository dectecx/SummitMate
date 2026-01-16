import 'package:hive/hive.dart';
import '../../models/itinerary_item.dart';
import '../../../core/error/result.dart';

/// Itinerary Repository 抽象介面
/// 定義行程資料存取的契約 (支援 Offline-First)
abstract interface class IItineraryRepository {
  /// 初始化
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得所有行程節點
  List<ItineraryItem> getAllItems();

  /// 依天數取得行程節點
  List<ItineraryItem> getItemsByDay(String day);

  /// 取得單一行程節點
  ItineraryItem? getItemByKey(dynamic key);

  /// 新增行程節點
  Future<Result<void, Exception>> addItem(ItineraryItem item);

  /// 更新行程節點
  Future<Result<void, Exception>> updateItem(dynamic key, ItineraryItem item);

  /// 刪除行程節點
  Future<Result<void, Exception>> deleteItem(dynamic key);

  /// 清除所有行程節點 (登出時使用)
  Future<Result<void, Exception>> clearAll();

  // ========== Check-In Operations ==========

  /// 打卡 - 設定實際時間
  Future<Result<void, Exception>> checkIn(dynamic key, DateTime time);

  /// 清除打卡
  Future<Result<void, Exception>> clearCheckIn(dynamic key);

  /// 重置所有打卡紀錄
  Future<Result<void, Exception>> resetAllCheckIns();

  // ========== Sync Operations ==========

  /// 批次覆寫行程 (從 Google Sheets 同步)
  Future<Result<void, Exception>> syncFromCloud(List<ItineraryItem> cloudItems);

  /// 儲存最後同步時間
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  Future<Result<void, Exception>> sync(String tripId);

  // ========== Watch ==========

  /// 監聽行程變更
  Stream<BoxEvent> watchAllItems();
}
