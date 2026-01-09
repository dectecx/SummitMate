import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/itinerary_item.dart';
import '../interfaces/i_itinerary_local_data_source.dart';

class ItineraryLocalDataSource implements IItineraryLocalDataSource {
  static const String _boxName = HiveBoxNames.itinerary;
  static const String _prefKeyLastSync = 'itin_last_sync_time';

  Box<ItineraryItem>? _box;

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

  @override
  List<ItineraryItem> getAll() {
    return box.values.toList();
  }

  @override
  ItineraryItem? getByKey(key) {
    return box.get(key);
  }

  @override
  Future<void> add(ItineraryItem item) async {
    await box.add(item);
  }

  @override
  Future<void> update(key, ItineraryItem item) async {
    await box.put(key, item);
  }

  @override
  Future<void> delete(key) async {
    await box.delete(key);
  }

  @override
  Future<void> clear() async {
    await box.clear();
  }

  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_prefKeyLastSync, time.toIso8601String());
  }

  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_prefKeyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
