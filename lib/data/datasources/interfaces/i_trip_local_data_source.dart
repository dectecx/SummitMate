import '../../models/trip.dart';

/// Trip Local Data Source Interface
/// Responsible for local storage operations (e.g., Hive)
abstract class ITripLocalDataSource {
  Future<void> init();
  List<Trip> getAllTrips();
  Trip? getTripById(String id);
  Future<void> addTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(String id);
  Future<void> setActiveTrip(String tripId);
  Trip? getActiveTrip();
}
