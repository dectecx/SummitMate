import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import '../../models/gear_library_item.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_gear_library_local_data_source.dart';

/// 裝備庫本地資料來源實作 (Hive)
@LazySingleton(as: IGearLibraryLocalDataSource)
class GearLibraryLocalDataSource implements IGearLibraryLocalDataSource {
  final Box<GearLibraryItem> _items;

  GearLibraryLocalDataSource({required HiveService hiveService})
    : _items = hiveService.getBox<GearLibraryItem>(HiveBoxNames.gearLibrary);

  @override
  List<GearLibraryItem> getAllItems() => _items.values.toList();

  @override
  GearLibraryItem? getById(String id) => _items.get(id);

  @override
  Future<void> saveItem(GearLibraryItem item) async {
    await _items.put(item.id, item);
  }

  @override
  Future<void> saveItems(List<GearLibraryItem> items) async {
    await _items.clear();
    for (var item in items) {
      await _items.put(item.id, item);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    await _items.delete(id);
  }

  @override
  Future<void> clear() async {
    await _items.clear();
  }
}
