import 'package:hive/hive.dart';
import '../../../core/constants.dart';
import '../../models/gear_item.dart';
import '../interfaces/i_gear_local_data_source.dart';

class GearLocalDataSource implements IGearLocalDataSource {
  static const String _boxName = HiveBoxNames.gear;
  Box<GearItem>? _box;

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<GearItem>(_boxName);
    } else {
      _box = Hive.box<GearItem>(_boxName);
    }
  }

  Box<GearItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('GearLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  List<GearItem> getAll() {
    return box.values.toList();
  }

  @override
  List<GearItem> getByTripId(String tripId) {
    return box.values.where((item) => item.tripId == tripId).toList();
  }

  @override
  List<GearItem> getByCategory(String category) {
    return box.values.where((item) => item.category == category).toList();
  }

  @override
  List<GearItem> getUnchecked() {
    return box.values.where((item) => !item.isChecked).toList();
  }

  @override
  Future<int> add(GearItem item) async {
    return await box.add(item);
  }

  @override
  Future<void> update(GearItem item) async {
    await item.save(); // HiveObject save
  }

  @override
  Future<void> delete(dynamic key) async {
    await box.delete(key);
  }

  @override
  Future<void> clearByTripId(String tripId) async {
    final toDelete = box.values.where((item) => item.tripId == tripId).toList();
    for (final item in toDelete) {
      await item.delete();
    }
  }

  @override
  Future<void> clearAll() async {
    await box.clear();
  }

  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }
}
