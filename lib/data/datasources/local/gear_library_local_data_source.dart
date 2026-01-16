import 'package:hive/hive.dart';
import '../../models/gear_library_item.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_gear_library_local_data_source.dart';

/// 裝備庫本地資料來源實作 (Hive)
class GearLibraryLocalDataSource implements IGearLibraryLocalDataSource {
  final HiveService _hiveService;
  Box<GearLibraryItem>? _box;

  GearLibraryLocalDataSource({required HiveService hiveService}) : _hiveService = hiveService;

  @override
  Future<void> init() async {
    _box = await _hiveService.openBox<GearLibraryItem>(HiveBoxNames.gearLibrary);
  }

  Box<GearLibraryItem> get _items {
    if (_box == null || !_box!.isOpen) {
      throw StateError('GearLibraryLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

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
