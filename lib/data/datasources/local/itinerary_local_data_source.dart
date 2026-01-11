import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/itinerary_item.dart';
import '../interfaces/i_itinerary_local_data_source.dart';

/// 行程項目 (ItineraryItem) 的本地資料來源實作 (使用 Hive)
class ItineraryLocalDataSource implements IItineraryLocalDataSource {
  static const String _boxName = HiveBoxNames.itinerary;
  static const String _prefKeyLastSync = 'itin_last_sync_time';

  Box<ItineraryItem>? _box;

  /// 初始化 Hive Box
  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<ItineraryItem>(_boxName);
    } else {
      _box = Hive.box<ItineraryItem>(_boxName);
    }
  }

  Box<ItineraryItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('ItineraryLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有行程
  @override
  List<ItineraryItem> getAll() {
    return box.values.toList();
  }

  /// 透過 Key 取得行程
  @override
  ItineraryItem? getByKey(key) {
    return box.get(key);
  }

  /// 新增行程
  ///
  /// [item] 欲新增的項目
  @override
  Future<void> add(ItineraryItem item) async {
    await box.add(item);
  }

  /// 更新行程
  ///
  /// [key] 目標項目的鍵值
  /// [item] 更新後的項目資料
  @override
  Future<void> update(key, ItineraryItem item) async {
    await box.put(key, item);
  }

  /// 刪除行程
  ///
  /// [key] 目標項目的鍵值
  @override
  Future<void> delete(key) async {
    await box.delete(key);
  }

  /// 清除所有行程
  @override
  Future<void> clear() async {
    await box.clear();
  }

  /// 監聽資料變更
  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }

  /// 儲存最後同步時間
  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_prefKeyLastSync, time.toIso8601String());
  }

  /// 取得最後同步時間
  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_prefKeyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
