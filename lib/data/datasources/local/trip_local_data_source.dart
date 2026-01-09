import 'package:hive/hive.dart';
import '../../models/trip.dart';
import '../../../core/constants.dart';
import '../../datasources/interfaces/i_trip_local_data_source.dart';

class TripLocalDataSource implements ITripLocalDataSource {
  Box<Trip>? _box;

  @override
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Trip>(HiveBoxNames.trips);
    }
  }

  Box<Trip> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('TripLocalDataSource not initialized');
    }
    return _box!;
  }

  @override
  List<Trip> getAllTrips() {
    return _box?.values.toList() ?? [];
  }

  @override
  Trip? getTripById(String id) {
    return _box?.get(id);
  }

  @override
  Future<void> addTrip(Trip trip) async {
    await box.put(trip.id, trip);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await box.put(trip.id, trip);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await box.delete(id);
  }

  @override
  Trip? getActiveTrip() {
    final trips = getAllTrips();
    try {
      return trips.firstWhere((t) => t.isActive);
    } catch (_) {
      return trips.isNotEmpty ? trips.first : null;
    }
  }

  @override
  Future<void> setActiveTrip(String tripId) async {
    final trips = getAllTrips();
    for (var trip in trips) {
      bool isActive = (trip.id == tripId);
      if (trip.isActive != isActive) {
        trip.isActive = isActive;
        await box.put(trip.id, trip);
      }
    }
  }
}
