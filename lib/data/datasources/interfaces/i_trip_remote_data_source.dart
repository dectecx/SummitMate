import '../../models/trip.dart';

/// Trip Remote Data Source Interface
/// Responsible for network operations (e.g., GAS API)
abstract class ITripRemoteDataSource {
  Future<List<Trip>> getTrips();
  Future<String> uploadTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(String tripId);
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  });
}
