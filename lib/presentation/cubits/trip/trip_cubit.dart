import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../domain/interfaces/i_sync_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../domain/interfaces/i_data_service.dart';
import 'trip_state.dart';

/// Manage Trip state and operations
class TripCubit extends Cubit<TripState> {
  static const String _source = 'TripCubit';

  final ITripRepository _tripRepository;
  final ISyncService _syncService;
  final Uuid _uuid = const Uuid();

  TripCubit({ITripRepository? tripRepository, ISyncService? syncService})
    : _tripRepository = tripRepository ?? getIt<ITripRepository>(),
      _syncService = syncService ?? getIt<ISyncService>(),
      super(const TripInitial());

  /// Load all trips and determine the active trip
  Future<void> loadTrips() async {
    try {
      emit(const TripLoading());

      final trips = _tripRepository.getAllTrips();
      // Sort by creation date descending (newest first)
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      var activeTrip = _tripRepository.getActiveTrip();

      // If no active trip but trips exist, force set the first one as active
      if (activeTrip == null && trips.isNotEmpty) {
        await _setActiveTripInternal(trips.first.id);
        activeTrip = _tripRepository.getActiveTrip();
      } else if (activeTrip == null && trips.isEmpty) {
        // Create default trip if completely empty??
        // Strategy: Let UI decide or do it here?
        // TripProvider created default trip. Let's replicate that logic generally or invoke explicitly.
        // For now, if empty, just emit empty list. UI can show "Create First Trip".
      }

      emit(TripLoaded(trips: trips, activeTrip: activeTrip));
    } catch (e) {
      LogService.error('Error loading trips: $e', source: _source);
      emit(TripError(e.toString()));
    }
  }

  /// Add a new trip
  Future<void> addTrip({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? coverImage,
    bool setAsActive = true,
  }) async {
    try {
      final trip = Trip(
        id: _uuid.v4(),
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        coverImage: coverImage,
        isActive: false, // will be set via setActiveTrip if needed
        createdAt: DateTime.now(),
      );

      await _tripRepository.addTrip(trip);
      LogService.info('Added trip: ${trip.name}', source: _source);

      if (setAsActive) {
        await setActiveTrip(trip.id);
      } else {
        loadTrips();
      }
    } catch (e) {
      LogService.error('Error adding trip: $e', source: _source);
      emit(TripError(e.toString()));
      // Re-load to ensure consistent state
      loadTrips();
    }
  }

  /// Import a trip (e.g. from Cloud)
  /// Note: This doesn't trigger SyncCubit directly. UI should handle that side-effect.
  Future<void> importTrip(Trip trip) async {
    try {
      await _tripRepository.addTrip(trip);
      LogService.info('Imported trip: ${trip.name} (${trip.id})', source: _source);
      await loadTrips();
    } catch (e) {
      LogService.error('Error importing trip: $e', source: _source);
      emit(TripError(e.toString()));
    }
  }

  /// Set the active trip
  Future<void> setActiveTrip(String tripId) async {
    try {
      await _setActiveTripInternal(tripId);
      loadTrips();
    } catch (e) {
      LogService.error('Error setting active trip: $e', source: _source);
      emit(TripError(e.toString()));
    }
  }

  Future<void> _setActiveTripInternal(String tripId) async {
    await _tripRepository.setActiveTrip(tripId);
    LogService.info('Set active trip: $tripId', source: _source);
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      final currentState = state;
      if (currentState is TripLoaded) {
        // If deleting active trip, switch to another one first
        if (currentState.activeTrip?.id == tripId) {
          final otherTrips = currentState.trips.where((t) => t.id != tripId);
          if (otherTrips.isNotEmpty) {
            await _setActiveTripInternal(otherTrips.first.id);
          }
        }
      }

      await _tripRepository.deleteTrip(tripId);
      LogService.info('Deleted trip: $tripId', source: _source);
      loadTrips();
    } catch (e) {
      LogService.error('Error deleting trip: $e', source: _source);
      emit(TripError(e.toString()));
    }
  }

  /// Update a trip
  Future<void> updateTrip(Trip trip) async {
    try {
      await _tripRepository.updateTrip(trip);
      LogService.info('Updated trip: ${trip.name}', source: _source);
      loadTrips();
    } catch (e) {
      LogService.error('Error updating trip: $e', source: _source);
      emit(TripError(e.toString()));
    }
  }

  /// Get Cloud Trips via SyncService
  Future<GetTripsResult> getCloudTrips() {
    return _syncService.getCloudTrips();
  }

  /// Get Trip by ID from current state or repository
  Trip? getTripById(String id) {
    if (state is TripLoaded) {
      final loadedParams = state as TripLoaded;
      try {
        return loadedParams.trips.firstWhere((t) => t.id == id);
      } catch (_) {}
    }
    return _tripRepository.getTripById(id);
  }

  // Create default trip (compatibility with Provider logic)
  Future<void> createDefaultTrip() async {
    await addTrip(name: '我的登山行程', startDate: DateTime.now());
  }

  /// Reset state (e.g. on logout)
  void reset() {
    emit(const TripInitial());
  }
}
