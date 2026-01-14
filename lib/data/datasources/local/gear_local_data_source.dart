import 'package:hive/hive.dart';
import '../../../core/constants.dart';
import '../../models/gear_item.dart';
import '../interfaces/i_gear_local_data_source.dart';
import '../../../infrastructure/tools/hive_service.dart';

/// 裝備項目 (GearItem) 的本地資料來源實作 (使用 Hive)
class GearLocalDataSource implements IGearLocalDataSource {
  static const String _boxName = HiveBoxNames.gear;
  final HiveService _hiveService;
  Box<GearItem>? _box;

  GearLocalDataSource({required HiveService hiveService}) : _hiveService = hiveService;

  /// 初始化 Hive Box
  @override
  Future<void> init() async {
    _box = await _hiveService.openBox<GearItem>(_boxName);
  }

  Box<GearItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('GearLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有裝備
  @override
  List<GearItem> getAll() {
    return box.values.toList();
  }

  /// 透過 Key 取得裝備
  ///
  /// [key] 裝備的本地鍵值
  @override
  GearItem? getByKey(dynamic key) {
    return box.get(key);
  }

  /// 根據行程 ID 取得裝備
  ///
  /// [tripId] 行程 ID
  @override
  List<GearItem> getByTripId(String tripId) {
    return box.values.where((item) => item.tripId == tripId).toList();
  }

  /// 根據類別取得裝備
  ///
  /// [category] 裝備類別
  @override
  List<GearItem> getByCategory(String category) {
    return box.values.where((item) => item.category == category).toList();
  }

  /// 取得未打包的裝備
  @override
  List<GearItem> getUnchecked() {
    return box.values.where((item) => !item.isChecked).toList();
  }

  /// 新增裝備
  ///
  /// [item] 欲新增的裝備
  @override
  Future<int> add(GearItem item) async {
    return await box.add(item);
  }

  /// 更新裝備
  ///
  /// [item] 更新後的裝備
  @override
  Future<void> update(GearItem item) async {
    await item.save(); // HiveObject save
  }

  /// 刪除裝備
  ///
  /// [key] 裝備的本地鍵值
  @override
  Future<void> delete(dynamic key) async {
    await box.delete(key);
  }

  /// 清除指定行程的裝備
  ///
  /// [tripId] 行程 ID
  @override
  Future<void> clearByTripId(String tripId) async {
    final toDelete = box.values.where((item) => item.tripId == tripId).toList();
    for (final item in toDelete) {
      await item.delete();
    }
  }

  /// 清除所有裝備
  @override
  Future<void> clearAll() async {
    await box.clear();
  }

  /// 監聽資料變更
  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }
}
