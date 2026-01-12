import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di.dart';
import '../../../data/models/gear_library_item.dart';
import '../../../data/models/enums/sync_status.dart';
import '../../../data/repositories/interfaces/i_gear_library_repository.dart';
import '../../../domain/interfaces/i_auth_service.dart';
import '../../../data/repositories/interfaces/i_gear_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'gear_library_state.dart';

/// 個人裝備庫 Cubit
///
/// 管理使用者個人的裝備庫存 (Personal Gear Library)。
/// 獨立於特定行程，作為裝備的來源資料中心。
/// 支援：
/// - 載入/搜尋個人裝備
/// - 新增/編輯/刪除個人裝備項目
/// - 同步至雲端 (Sync)
class GearLibraryCubit extends Cubit<GearLibraryState> {
  final IGearLibraryRepository _repository;
  final IGearRepository _gearRepository;
  final ITripRepository _tripRepository;
  final IAuthService _authService;

  GearLibraryCubit({
    IGearLibraryRepository? repository,
    IGearRepository? gearRepository,
    ITripRepository? tripRepository,
    IAuthService? authService,
  }) : _repository = repository ?? getIt<IGearLibraryRepository>(),
       _gearRepository = gearRepository ?? getIt<IGearRepository>(),
       _tripRepository = tripRepository ?? getIt<ITripRepository>(),
       _authService = authService ?? getIt<IAuthService>(),
       super(const GearLibraryInitial());

  Future<void> loadItems() async {
    emit(const GearLibraryLoading());
    try {
      final userId = _authService.currentUserId ?? 'guest';
      final items = _repository.getAllItems(userId);
      emit(GearLibraryLoaded(items: items));
    } catch (e) {
      LogService.error('Failed to load gear library: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  void reload() {
    try {
      final userId = _authService.currentUserId ?? 'guest';
      final items = _repository.getAllItems(userId);
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

  /// 新增庫存項目
  ///
  /// [name] 名稱
  /// [weight] 重量 (g)
  /// [category] 分類
  /// [notes] 備註 (可選)
  Future<void> addItem({required String name, required double weight, required String category, String? notes}) async {
    try {
      final userId = _authService.currentUserId ?? 'guest';

      final item = GearLibraryItem(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        weight: weight,
        category: category,
        notes: notes,
        createdAt: DateTime.now(),
        createdBy: userId,
        syncStatus: SyncStatus.pendingCreate,
      );
      await _repository.addItem(item);
      reload();
    } catch (e) {
      LogService.error('Failed to add library item: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  /// 更新庫存項目
  ///
  /// [item] 更新後的項目
  Future<void> updateItem(GearLibraryItem item) async {
    try {
      final userId = _authService.currentUserId ?? 'guest';
      item.updatedBy = userId;

      await _repository.updateItem(item);
      // 同步更新已連結的裝備項目 (邏輯遷移自 Provider)
      await _syncLinkedGear(item);
      reload();
    } catch (e) {
      LogService.error('Failed to update library item: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  /// 刪除庫存項目
  ///
  /// [uuid] 項目 UUID
  Future<void> deleteItem(String id) async {
    try {
      // 解除連結 (Unlink)
      final allGear = _gearRepository.getAllItems();
      final linkedItems = allGear.where((g) => g.libraryItemId == id).toList();

      for (final gear in linkedItems) {
        gear.libraryItemId = null;
        await _gearRepository.updateItem(gear); // 假設 updateItem 會處理 save
      }

      await _repository.deleteItem(id);
      reload();
    } catch (e) {
      LogService.error('Failed to delete library item: $e', source: 'GearLibraryCubit');
      emit(GearLibraryError(e.toString()));
    }
  }

  /// 切換封存狀態
  ///
  /// [uuid] 項目 UUID
  Future<void> toggleArchive(String id) async {
    try {
      final item = _repository.getById(id);
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

  /// 匯入項目列表
  ///
  /// [items] 欲匯入的項目清單
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
      final linkedItems = allGear.where((g) => g.libraryItemId == libItem.id).toList();

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
  GearLibraryItem? getById(String id) => _repository.getById(id);

  /// 取得連結此裝備的行程資訊
  ///
  /// [libraryItemId] 裝備庫 Item UUID
  /// 回傳: List of {tripName, startDate, tripId}
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
