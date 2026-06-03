import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/repositories/i_itinerary_repository.dart';
import '../datasources/interfaces/i_itinerary_local_data_source.dart';

/// 行程節點 Repository 實作
@LazySingleton(as: IItineraryRepository)
class ItineraryRepository implements IItineraryRepository {
  final IItineraryLocalDataSource _localDataSource;

  ItineraryRepository({required IItineraryLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  Future<List<ItineraryItem>> getByTripId(String tripId) async {
    return await _localDataSource.getByTripId(tripId);
  }

  @override
  Future<ItineraryItem?> getById(String id) async {
    return await _localDataSource.getById(id);
  }

  @override
  Future<Result<void, Exception>> add(ItineraryItem item) async {
    try {
      final now = DateTime.now();
      final marked = item.copyWith(
        syncStatus: SyncStatus.pendingCreate,
        createdAt: item.createdAt ?? now,
        updatedAt: now,
      );
      await _localDataSource.addItem(marked);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> update(ItineraryItem item) async {
    try {
      final existing = await _localDataSource.getById(item.id);
      final newStatus = existing?.syncStatus == SyncStatus.pendingCreate
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate;
      final marked = item.copyWith(syncStatus: newStatus, updatedAt: DateTime.now());
      await _localDataSource.updateItem(marked);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> delete(String id) async {
    try {
      final existing = await _localDataSource.getById(id);
      if (existing == null) {
        return const Success(null);
      }
      if (existing.syncStatus == SyncStatus.pendingCreate) {
        await _localDataSource.deleteById(id);
      } else {
        await _localDataSource.updateItem(
          existing.copyWith(syncStatus: SyncStatus.pendingDelete, updatedAt: DateTime.now()),
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async {
    try {
      final items = await _localDataSource.getByTripId(tripId);
      for (final item in items) {
        if (item.syncStatus == SyncStatus.pendingCreate) {
          await _localDataSource.deleteById(item.id);
        } else {
          await _localDataSource.updateItem(
            item.copyWith(syncStatus: SyncStatus.pendingDelete, updatedAt: DateTime.now()),
          );
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> saveAll(List<ItineraryItem> items) async {
    try {
      // 策略：保留本地打卡紀錄 (Drift 實作中應考慮 upsert 或手動合併)
      final existingItems = await _localDataSource.getAll();
      final localDataMap = {for (var item in existingItems) item.id: item};

      await _localDataSource.clear();

      for (final item in items) {
        var itemToSave = item;
        final localItem = localDataMap[item.id];
        if (localItem != null) {
          // 合併本地打卡狀態
          itemToSave = item.copyWith(
            isCheckedIn: localItem.isCheckedIn,
            // TODO: 若 ItineraryItem 有 actualTime 等屬性，在此合併
          );
        }
        await _localDataSource.addItem(itemToSave);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> toggleCheckIn(String id) async {
    try {
      final item = await _localDataSource.getById(id);
      if (item != null) {
        final newStatus = item.syncStatus == SyncStatus.pendingCreate
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate;
        final updatedItem = item.copyWith(
          isCheckedIn: !item.isCheckedIn,
          checkedInAt: !item.isCheckedIn ? DateTime.now() : null,
          syncStatus: newStatus,
          updatedAt: DateTime.now(),
        );
        await _localDataSource.updateItem(updatedItem);
        return const Success(null);
      }
      return const Failure(GeneralException('Item not found'));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateLocalId(String oldId, String newId) async {
    try {
      await _localDataSource.migrateId(oldId, newId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
