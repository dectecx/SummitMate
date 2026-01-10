import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../domain/interfaces/i_sync_service.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'itinerary_state.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final IItineraryRepository _repository;
  final ITripRepository _tripRepository;
  // final ISyncService _syncService;
  // final IConnectivityService _connectivityService;

  static const String _source = 'ItineraryCubit';

  ItineraryCubit({
    IItineraryRepository? repository,
    ITripRepository? tripRepository,
    ISyncService? syncService,
    IConnectivityService? connectivityService,
  }) : _repository = repository ?? getIt<IItineraryRepository>(),
       _tripRepository = tripRepository ?? getIt<ITripRepository>(),
       // _syncService = syncService ?? getIt<ISyncService>(),
       // _connectivityService = connectivityService ?? getIt<IConnectivityService>(),
       super(const ItineraryInitial());

  String? get _currentTripId => _tripRepository.getActiveTrip()?.id;

  /// Load itinerary items for the active trip
  Future<void> loadItinerary() async {
    try {
      if (state is! ItineraryLoaded) {
        emit(const ItineraryLoading());
      }

      final currentTripId = _currentTripId;
      if (currentTripId == null) {
        // No active trip, empty state
        emit(const ItineraryLoaded(items: []));
        return;
      }

      final allItems = _repository.getAllItems();
      final tripItems = allItems.where((item) => item.tripId == currentTripId).toList();

      // Preserve current selection if reloading
      String selectedDay = 'D1';
      bool isEditMode = false;
      if (state is ItineraryLoaded) {
        selectedDay = (state as ItineraryLoaded).selectedDay;
        isEditMode = (state as ItineraryLoaded).isEditMode;
      }

      emit(ItineraryLoaded(items: tripItems, selectedDay: selectedDay, isEditMode: isEditMode));

      LogService.debug('Loaded ${tripItems.length} itinerary items', source: _source);
    } catch (e) {
      LogService.error('Failed to load itinerary: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// Select a different day
  void selectDay(String day) {
    if (state is ItineraryLoaded) {
      emit((state as ItineraryLoaded).copyWith(selectedDay: day));
    }
  }

  /// Toggle edit mode
  void toggleEditMode() {
    if (state is ItineraryLoaded) {
      final current = state as ItineraryLoaded;
      emit(current.copyWith(isEditMode: !current.isEditMode));
    }
  }

  /// Check-in logic
  Future<void> checkIn(dynamic key, {DateTime? time}) async {
    try {
      final checkInTime = time ?? DateTime.now();
      await _repository.checkIn(key, checkInTime);
      LogService.info('Check-in: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Check-in failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
      // Recover to loaded state after error?
      // For now, let UI handle error state or re-load
      loadItinerary();
    }
  }

  /// Clear check-in
  Future<void> clearCheckIn(dynamic key) async {
    try {
      await _repository.clearCheckIn(key);
      LogService.info('Clear check-in: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Clear check-in failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
      loadItinerary();
    }
  }

  /// Add new item
  Future<void> addItem(ItineraryItem item) async {
    try {
      // Ensure tripId is set correctly if not present (though caller should probably handle this)
      var ItemToAdd = item;
      if (item.tripId.isEmpty && _currentTripId != null) {
        ItemToAdd = ItineraryItem(
          uuid: item.uuid,
          tripId: _currentTripId!,
          day: item.day,
          name: item.name,
          estTime: item.estTime,
          altitude: item.altitude,
          distance: item.distance,
          note: item.note,
          imageAsset: item.imageAsset,
          isCheckedIn: item.isCheckedIn,
          checkedInAt: item.checkedInAt,
        );
      }

      await _repository.addItem(ItemToAdd);
      LogService.info('Added item: ${item.name}', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Add item failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// Update item
  Future<void> updateItem(dynamic key, ItineraryItem item) async {
    try {
      await _repository.updateItem(key, item);
      LogService.info('Updated item: ${item.name}', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Update item failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// Delete item
  Future<void> deleteItem(dynamic key) async {
    try {
      await _repository.deleteItem(key);
      LogService.info('Deleted item: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Delete item failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// Reset state (e.g. on logout)
  void reset() {
    emit(const ItineraryInitial());
  }
}
