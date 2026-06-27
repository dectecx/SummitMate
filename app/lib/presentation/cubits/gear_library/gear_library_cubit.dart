import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import 'package:uuid/uuid.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'gear_library_state.dart';

@injectable
class GearLibraryCubit extends Cubit<GearLibraryState> with SafeEmitMixin<GearLibraryState> {
  final IGearLibraryRepository _repository;
  final IGearRepository _gearRepository;
  final IAuthService _authService;
  final IGearLibrarySyncService _syncService;

  GearLibraryCubit(this._repository, this._gearRepository, this._authService, this._syncService)
    : super(const GearLibraryInitial());

  Future<void> loadItems() async {
    safeEmit(const GearLibraryLoading());
    try {
      final userId = _authService.currentUserId ?? 'guest';
      final items = await _repository.getAll(userId);
      safeEmit(GearLibraryLoaded(items: items));
    } catch (e) {
      LogService.error('Failed to load gear library: $e', source: 'GearLibraryCubit');
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  Future<void> reload() async {
    try {
      final userId = _authService.currentUserId ?? 'guest';
      final items = await _repository.getAll(userId);
      if (state is GearLibraryLoaded) {
        safeEmit((state as GearLibraryLoaded).copyWith(items: items));
      } else {
        safeEmit(GearLibraryLoaded(items: items));
      }
    } catch (e) {
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  // ========================================
  // Filter
  // ========================================

  void setSearchQuery(String query) {
    if (state is GearLibraryLoaded) {
      safeEmit((state as GearLibraryLoaded).copyWith(searchQuery: query));
    }
  }

  void selectCategory(String? category) {
    if (state is GearLibraryLoaded) {
      safeEmit((state as GearLibraryLoaded).copyWith(selectedCategory: category, clearCategory: category == null));
    }
  }

  // ========================================
  // CRUD
  // ========================================

  /// 新增庫存項目
  Future<void> addItem({required String name, required double weight, required String category, String? notes}) async {
    try {
      final userId = _authService.currentUserId ?? 'guest';

      final item = GearLibraryItem(
        id: const Uuid().v7(),
        userId: userId,
        name: name,
        weight: weight,
        category: category,
        notes: notes,
        createdAt: DateTime.now(),
        createdBy: userId,
        updatedAt: DateTime.now(),
        updatedBy: userId,
        syncStatus: SyncStatus.pendingCreate,
      );
      await _repository.add(item);
      await reload();
    } catch (e) {
      LogService.error('Failed to add library item: $e', source: 'GearLibraryCubit');
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新庫存項目，並同步連結的行程裝備
  Future<void> updateItem(GearLibraryItem item) async {
    final userId = _authService.currentUserId ?? 'guest';
    final updatedItem = item.copyWith(updatedBy: userId, updatedAt: DateTime.now());

    try {
      await _repository.update(updatedItem);
      await reload();
    } catch (e) {
      LogService.error('Failed to update library item: $e', source: 'GearLibraryCubit');
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
      return;
    }

    // 同步連結行程裝備（非核心路徑，失敗記錄 warning 但不阻斷主流程）
    try {
      await _syncService.syncLinkedGear(updatedItem);
    } catch (e) {
      LogService.warning('Failed to sync linked gear after update: $e', source: 'GearLibraryCubit');
    }
  }

  /// 刪除庫存項目
  Future<void> deleteItem(String id) async {
    try {
      final allGear = await _gearRepository.getAllItems();
      final linkedItems = allGear.where((g) => g.libraryItemId == id).toList();

      for (final gear in linkedItems) {
        final updatedGear = gear.copyWith(libraryItemId: null);
        await _gearRepository.updateItem(updatedGear);
      }

      await _repository.delete(id);
      await reload();
    } catch (e) {
      LogService.error('Failed to delete library item: $e', source: 'GearLibraryCubit');
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 切換封存狀態
  Future<void> toggleArchive(String id) async {
    try {
      final item = await _repository.getById(id);
      if (item != null) {
        final updatedItem = item.copyWith(isArchived: !item.isArchived, updatedAt: DateTime.now());
        await _repository.update(updatedItem);
        await reload();
      }
    } catch (e) {
      LogService.error('Failed to toggle archive: $e', source: 'GearLibraryCubit');
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  // ========================================
  // Sync Logic
  // ========================================

  /// 匯入項目列表
  Future<void> importItems(List<GearLibraryItem> items) async {
    try {
      await _repository.importAll(items);
      await reload();
    } catch (e) {
      LogService.error('Failed to import items: $e', source: 'GearLibraryCubit');
      safeEmit(GearLibraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 上傳本地庫存至雲端 (Sync to Cloud)
  Future<Result<int, Exception>> uploadLibrary() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return Failure(Exception('未登入'));

      final items = await _repository.getAll(userId);
      final result = await _repository.syncRemoteItems(items);
      if (result is Failure) return Failure(result.exception);

      LogService.info('Gear Library 上傳成功, 項目數: ${items.length}', source: 'GearLibraryCubit');
      return Success(items.length);
    } catch (e) {
      LogService.error('Gear Library 上傳失敗: $e', source: 'GearLibraryCubit');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 從雲端下載庫存 (Sync from Cloud)
  Future<Result<int, Exception>> downloadLibrary() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return Failure(Exception('未登入'));

      final cloudResult = await _repository.getRemoteItems(limit: 1000);
      final cloudItems = switch (cloudResult) {
        Success(value: final p) => p.items,
        Failure(exception: final e) => throw e,
      };
      await _repository.importAll(cloudItems);

      await reload();
      LogService.info('Gear Library 下載成功, 項目數: ${cloudItems.length}', source: 'GearLibraryCubit');
      return Success(cloudItems.length);
    } catch (e) {
      LogService.error('Gear Library 下載失敗: $e', source: 'GearLibraryCubit');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // Helper getters
  Future<GearLibraryItem?> getById(String id) => _repository.getById(id);

  /// 取得連結此裝備的行程資訊
  Future<List<LinkedTripInfo>> getLinkedTrips(String libraryItemId) =>
      _syncService.getLinkedTrips(libraryItemId);

  void reset() {
    safeEmit(const GearLibraryInitial());
  }
}
