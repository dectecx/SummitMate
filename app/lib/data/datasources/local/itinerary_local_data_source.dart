import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di/injection.dart';
import '../../models/itinerary_item_model.dart';
import '../interfaces/i_itinerary_local_data_source.dart';
import '../../../infrastructure/tools/hive_service.dart';

/// 行程項目模型 (ItineraryItemModel) 的本地資料來源實作 (使用 Hive)
@LazySingleton(as: IItineraryLocalDataSource)
class ItineraryLocalDataSource implements IItineraryLocalDataSource {
  static const String _boxName = HiveBoxNames.itinerary;
  static const String _prefKeyLastSync = 'itin_last_sync_time';

  final Box<ItineraryItemModel> box;

  ItineraryLocalDataSource({required HiveService hiveService}) : box = hiveService.getBox<ItineraryItemModel>(_boxName);

  @override
  List<ItineraryItemModel> getAll() {
    return box.values.toList();
  }

  @override
  List<ItineraryItemModel> getByTripId(String tripId) {
    return box.values.where((item) => item.tripId == tripId).toList();
  }

  @override
  ItineraryItemModel? getByKey(key) {
    return box.get(key);
  }

  @override
  ItineraryItemModel? getById(String id) {
    try {
      return box.values.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(ItineraryItemModel item) async {
    await box.add(item);
  }

  @override
  Future<void> update(ItineraryItemModel item) async {
    if (item.isInBox) {
      await item.save();
    } else {
      final original = getById(item.id);
      if (original != null) {
        original.day = item.day;
        original.name = item.name;
        original.estTime = item.estTime;
        original.actualTime = item.actualTime;
        original.altitude = item.altitude;
        original.distance = item.distance;
        original.note = item.note;
        original.imageAsset = item.imageAsset;
        original.isCheckedIn = item.isCheckedIn;
        original.checkedInAt = item.checkedInAt;
        original.updatedAt = DateTime.now();
        await original.save();
      } else {
        await box.add(item);
      }
    }
  }

  @override
  Future<void> delete(key) async {
    await box.delete(key);
  }

  @override
  Future<void> deleteById(String id) async {
    final item = getById(id);
    if (item != null) {
      await item.delete();
    }
  }

  @override
  Future<void> clearByTripId(String tripId) async {
    final toDelete = box.values.where((item) => item.tripId == tripId).toList();
    for (final item in toDelete) {
      await item.delete();
    }
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
