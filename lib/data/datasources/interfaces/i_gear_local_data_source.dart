import 'package:hive/hive.dart';
import '../../models/gear_item.dart';

abstract class IGearLocalDataSource {
  Future<void> init();

  List<GearItem> getAll();
  List<GearItem> getByTripId(String tripId);
  List<GearItem> getByCategory(String category);
  List<GearItem> getUnchecked();
  GearItem? getByKey(dynamic key);

  Future<int> add(GearItem item);
  Future<void> update(GearItem item);
  Future<void> delete(dynamic key);

  Future<void> clearByTripId(String tripId);
  Future<void> clearAll();

  Stream<BoxEvent> watch();
}
