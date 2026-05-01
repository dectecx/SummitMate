import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import '../../../core/constants.dart';
import '../../models/gear_item.dart';
import '../interfaces/i_gear_local_data_source.dart';
import '../../../infrastructure/tools/hive_service.dart';

/// 裝備項目模型 (GearItemModel) 的本地資料來源實作 (使用 Hive)
@LazySingleton(as: IGearLocalDataSource)
class GearLocalDataSource implements IGearLocalDataSource {
  static const String _boxName = HiveBoxNames.gear;
  final Box<GearItemModel> box;

  GearLocalDataSource({required HiveService hiveService}) : box = hiveService.getBox<GearItemModel>(_boxName);

  /// 取得所有裝備
  @override
  List<GearItemModel> getAll() {
    return box.values.toList();
  }

  /// 透過 Key 取得裝備
  @override
  GearItemModel? getByKey(dynamic key) {
    return box.get(key);
  }

  /// 透過 ID 取得裝備 (UUID)
  @override
  GearItemModel? getById(String id) {
    try {
      return box.values.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根據行程 ID 取得裝備
  @override
  List<GearItemModel> getByTripId(String tripId) {
    return box.values.where((item) => item.tripId == tripId).toList();
  }

  /// 根據類別取得裝備
  @override
  List<GearItemModel> getByCategory(String category) {
    return box.values.where((item) => item.category == category).toList();
  }

  /// 取得未打包的裝備
  @override
  List<GearItemModel> getUnchecked() {
    return box.values.where((item) => !item.isChecked).toList();
  }

  /// 新增裝備
  @override
  Future<int> add(GearItemModel item) async {
    return await box.add(item);
  }

  /// 更新裝備
  @override
  Future<void> update(GearItemModel item) async {
    if (item.isInBox) {
      await item.save();
    } else {
      // 處理 detached 物件，根據 ID 尋找並更新
      final original = getById(item.id);
      if (original != null) {
        // 更新原有物件的屬性
        original.name = item.name;
        original.weight = item.weight;
        original.category = item.category;
        original.isChecked = item.isChecked;
        original.quantity = item.quantity;
        original.orderIndex = item.orderIndex;
        original.libraryItemId = item.libraryItemId;
        original.updatedAt = DateTime.now();
        await original.save();
      } else {
        // 若找不到則新增 (或者拋出異常，視業務需求而定)
        await box.add(item);
      }
    }
  }

  /// 刪除裝備 (透過 Key)
  @override
  Future<void> delete(dynamic key) async {
    await box.delete(key);
  }

  /// 刪除裝備 (透過 ID)
  @override
  Future<void> deleteById(String id) async {
    final item = getById(id);
    if (item != null) {
      await item.delete();
    }
  }

  /// 清除指定行程的裝備
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
