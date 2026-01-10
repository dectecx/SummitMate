import '../models/trip.dart';

import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_trip_repository.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';

/// Trip Repository with Offline-First support
/// Delegates to LocalDataSource by default, and optionally syncs with RemoteDataSource
class TripRepository implements ITripRepository {
  static const String _source = 'TripRepository';

  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  TripRepository({required ITripLocalDataSource localDataSource, required ITripRemoteDataSource remoteDataSource})
    : _localDataSource = localDataSource,
      _remoteDataSource = remoteDataSource;

  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  @override
  List<Trip> getAllTrips() {
    return _localDataSource.getAllTrips();
  }

  @override
  Trip? getActiveTrip() {
    return _localDataSource.getActiveTrip();
  }

  @override
  Trip? getTripById(String id) {
    return _localDataSource.getTripById(id);
  }

  @override
  Future<void> addTrip(Trip trip) async {
    LogService.info('Adding trip: ${trip.name} (Local)', source: _source);
    await _localDataSource.addTrip(trip);

    // Optional: Attempt immediate sync if online?
    // For now, we stay consistent with basic "Local First, Manual Sync" pattern unless requested.
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await _localDataSource.updateTrip(trip);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await _localDataSource.deleteTrip(id);
  }

  @override
  Future<void> setActiveTrip(String tripId) async {
    await _localDataSource.setActiveTrip(tripId);
  }

  @override
  DateTime? getLastSyncTime() {
    // Moved to Settings or Metadata repository if needed, or kept here if we implement sync timestamps in LocalDataSource
    return null;
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    //
  }

  @override
  Future<List<Trip>> getRemoteTrips() async {
    return _remoteDataSource.getTrips();
  }

  @override
  Future<String> uploadTripToRemote(Trip trip) async {
    return _remoteDataSource.uploadTrip(trip);
  }

  @override
  Future<void> deleteRemoteTrip(String id) async {
    await _remoteDataSource.deleteTrip(id);
  }

  @override
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async {
    return _remoteDataSource.uploadFullTrip(trip: trip, itineraryItems: itineraryItems, gearItems: gearItems);
  }
}
