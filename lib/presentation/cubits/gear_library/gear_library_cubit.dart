import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../data/models/gear_library_item.dart';
import '../../../data/repositories/interfaces/i_gear_library_repository.dart';
import '../../../data/repositories/interfaces/i_gear_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'gear_library_state.dart';

class GearLibraryCubit extends Cubit<GearLibraryState> {
  final IGearLibraryRepository _repository;
  final IGearRepository _gearRepository;
  final ITripRepository _tripRepository;

  GearLibraryCubit({
    IGearLibraryRepository? repository,
    IGearRepository? gearRepository,
    ITripRepository? tripRepository,
  }) : _repository = repository ?? getIt<IGearLibraryRepository>(),
       _gearRepository = gearRepository ?? getIt<IGearRepository>(),
       _tripRepository = tripRepository ?? getIt<ITripRepository>(),
       super(const GearLibraryInitial());

  Future<void> loadItems() async {
    emit(const GearLibraryLoading());
    try {
      final items = _repository.getAllItems();
      emit(GearLibraryLoaded(items: items));
    } catch (e) {
      LogService.error('Failed to load gear library: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  void reload() {
    try {
      final items = _repository.getAllItems();
      if (state is GearLibraryLoaded) {
        emit((state as GearLibraryLoaded).copyWith(items: items));
      } else {
        emit(GearLibraryLoaded(items: items));
      }
    } catch (e) {
      emit(GearLibraryError(e.toString()));
    }
  }

  // ========================================
  // Filter
  // ========================================

  void setSearchQuery(String query) {
    if (state is GearLibraryLoaded) {
      emit((state as GearLibraryLoaded).copyWith(searchQuery: query));
    }
  }

  void selectCategory(String? category) {
    if (state is GearLibraryLoaded) {
      emit((state as GearLibraryLoaded).copyWith(selectedCategory: category, clearCategory: category == null));
    }
  }

  // ========================================
  // CRUD
  // ========================================

  Future<void> addItem({required String name, required double weight, required String category, String? notes}) async {
    try {
      final item = GearLibraryItem(name: name, weight: weight, category: category, notes: notes);
      await _repository.addItem(item);
      reload();
    } catch (e) {
      LogService.error('Failed to add library item: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  Future<void> updateItem(GearLibraryItem item) async {
    try {
      await _repository.updateItem(item);
      // 同步更新已連結的裝備項目 (邏輯遷移自 Provider)
      await _syncLinkedGear(item);
      reload();
    } catch (e) {
      LogService.error('Failed to update library item: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  Future<void> deleteItem(String uuid) async {
    try {
      // 解除連結 (Unlink)
      final allGear = _gearRepository.getAllItems();
      final linkedItems = allGear.where((g) => g.libraryItemId == uuid).toList();

      for (final gear in linkedItems) {
        gear.libraryItemId = null;
        await _gearRepository.updateItem(gear); // 假設 updateItem 會處理 save
      }

      await _repository.deleteItem(uuid);
      reload();
    } catch (e) {
      LogService.error('Failed to delete library item: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  Future<void> toggleArchive(String uuid) async {
    try {
      final item = _repository.getById(uuid);
      if (item != null) {
        item.isArchived = !item.isArchived;
        await _repository.updateItem(item);
        reload();
      }
    } catch (e) {
      LogService.error('Failed to toggle archive: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  // ========================================
  // Sync Logic
  // ========================================

  Future<void> importItems(List<GearLibraryItem> items) async {
    try {
      await _repository.importItems(items);
      reload();
    } catch (e) {
      LogService.error('Failed to import items: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  Future<void> _syncLinkedGear(GearLibraryItem libItem) async {
    try {
      final allGear = _gearRepository.getAllItems();
      final linkedItems = allGear.where((g) => g.libraryItemId == libItem.uuid).toList();

      if (linkedItems.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final gear in linkedItems) {
        if (gear.tripId != null) {
          final trip = _tripRepository.getTripById(gear.tripId!);
          if (trip != null) {
            final isArchived = (trip.endDate != null && trip.endDate!.isBefore(today)) || !trip.isActive;
            if (isArchived) continue;
          }
        }

        bool changed = false;
        if (gear.name != libItem.name) {
          gear.name = libItem.name;
          changed = true;
        }
        if (gear.weight != libItem.weight) {
          gear.weight = libItem.weight;
          changed = true;
        }
        if (gear.category != libItem.category) {
          gear.category = libItem.category;
          changed = true;
        }

        if (changed) {
          await _gearRepository.updateItem(gear);
        }
      }
    } catch (e) {
      LogService.error('Failed to sync linked gear: $e', source: 'GearLibraryCubit');
    }
  }

  // Helper getters
  GearLibraryItem? getById(String uuid) => _repository.getById(uuid);

  List<Map<String, dynamic>> getLinkedTrips(String libraryItemId) {
    final allGear = _gearRepository.getAllItems();
    final linkedGear = allGear.where((g) => g.libraryItemId == libraryItemId).toList();

    final Set<String> tripIds = linkedGear.map((g) => g.tripId).whereType<String>().toSet();

    final List<Map<String, dynamic>> result = [];
    for (final tid in tripIds) {
      final trip = _tripRepository.getTripById(tid);
      if (trip != null) {
        result.add({'tripName': trip.name, 'startDate': trip.startDate, 'tripId': trip.id});
      }
    }
    return result;
  }

  void reset() {
    emit(const GearLibraryInitial());
  }
}
