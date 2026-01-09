import 'package:hive/hive.dart';
import '../../models/itinerary_item.dart';

abstract class IItineraryLocalDataSource {
  Future<void> init();

  List<ItineraryItem> getAll();
  ItineraryItem? getByKey(dynamic key);
  Future<void> add(ItineraryItem item);
  Future<void> update(dynamic key, ItineraryItem item);
  Future<void> delete(dynamic key);
  Future<void> clear();
  
  Stream<BoxEvent> watch();

  Future<void> saveLastSyncTime(DateTime time);
  DateTime? getLastSyncTime();
}
