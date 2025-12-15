import 'package:isar/isar.dart';
import '../models/itinerary_item.dart';

/// Itinerary Repository
/// 管理行程節點的 CRUD 操作
class ItineraryRepository {
  final Isar _isar;

  ItineraryRepository(this._isar);

  /// 取得所有行程節點
  Future<List<ItineraryItem>> getAllItems() async {
    return await _isar.itineraryItems.where().findAll();
  }

  /// 依天數取得行程節點
  Future<List<ItineraryItem>> getItemsByDay(String day) async {
    return await _isar.itineraryItems
        .filter()
        .dayEqualTo(day)
        .findAll();
  }

  /// 取得單一行程節點
  Future<ItineraryItem?> getItemById(int id) async {
    return await _isar.itineraryItems.get(id);
  }

  /// 打卡 - 設定實際時間
  Future<void> checkIn(int id, DateTime time) async {
    final item = await getItemById(id);
    if (item == null) return;

    item.actualTime = time;
    await _isar.writeTxn(() async {
      await _isar.itineraryItems.put(item);
    });
  }

  /// 清除打卡
  Future<void> clearCheckIn(int id) async {
    final item = await getItemById(id);
    if (item == null) return;

    item.actualTime = null;
    await _isar.writeTxn(() async {
      await _isar.itineraryItems.put(item);
    });
  }

  /// 批次覆寫行程 (從 Google Sheets 同步)
  /// 保留 actualTime 本地資料
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems) async {
    await _isar.writeTxn(() async {
      // 取得現有資料以保留 actualTime
      final existing = await _isar.itineraryItems.where().findAll();
      final actualTimeMap = <String, DateTime?>{};
      for (final item in existing) {
        final key = '${item.day}_${item.name}';
        actualTimeMap[key] = item.actualTime;
      }

      // 清除舊資料
      await _isar.itineraryItems.clear();

      // 寫入新資料並還原 actualTime
      for (final item in cloudItems) {
        final key = '${item.day}_${item.name}';
        item.actualTime = actualTimeMap[key];
      }
      await _isar.itineraryItems.putAll(cloudItems);
    });
  }

  /// 監聽行程變更
  Stream<List<ItineraryItem>> watchAllItems() {
    return _isar.itineraryItems.where().watch(fireImmediately: true);
  }

  /// 重置所有打卡紀錄
  Future<void> resetAllCheckIns() async {
    await _isar.writeTxn(() async {
      final items = await _isar.itineraryItems.where().findAll();
      for (final item in items) {
        item.actualTime = null;
      }
      await _isar.itineraryItems.putAll(items);
    });
  }
}
