import 'package:hive/hive.dart';
import '../models/itinerary_item.dart';

/// Itinerary Repository
/// 管理行程節點的 CRUD 操作
class ItineraryRepository {
  static const String _boxName = 'itinerary';

  Box<ItineraryItem>? _box;

  /// 開啟 Box
  Future<void> init() async {
    _box = await Hive.openBox<ItineraryItem>(_boxName);
  }

  /// 取得 Box
  Box<ItineraryItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('ItineraryRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有行程節點
  List<ItineraryItem> getAllItems() {
    return box.values.toList();
  }

  /// 依天數取得行程節點
  List<ItineraryItem> getItemsByDay(String day) {
    return box.values.where((item) => item.day == day).toList();
  }

  /// 取得單一行程節點
  ItineraryItem? getItemByKey(dynamic key) {
    return box.get(key);
  }

  /// 打卡 - 設定實際時間
  Future<void> checkIn(dynamic key, DateTime time) async {
    final item = box.get(key);
    if (item == null) return;

    item.actualTime = time;
    await item.save();
  }

  /// 清除打卡
  Future<void> clearCheckIn(dynamic key) async {
    final item = box.get(key);
    if (item == null) return;

    item.actualTime = null;
    await item.save();
  }

  /// 批次覆寫行程 (從 Google Sheets 同步)
  /// 保留 actualTime 本地資料
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems) async {
    // 取得現有資料以保留 actualTime
    final existing = box.values.toList();
    final actualTimeMap = <String, DateTime?>{};
    for (final item in existing) {
      final key = '${item.day}_${item.name}';
      actualTimeMap[key] = item.actualTime;
    }

    // 清除舊資料
    await box.clear();

    // 寫入新資料並還原 actualTime
    for (final item in cloudItems) {
      final key = '${item.day}_${item.name}';
      item.actualTime = actualTimeMap[key];
      await box.add(item);
    }
  }

  /// 監聽行程變更
  Stream<BoxEvent> watchAllItems() {
    return box.watch();
  }

  /// 重置所有打卡紀錄
  Future<void> resetAllCheckIns() async {
    for (final item in box.values) {
      item.actualTime = null;
      await item.save();
    }
  }
}
