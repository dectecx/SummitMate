import 'package:injectable/injectable.dart';
import '../../../domain/entities/itinerary_item.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/interfaces/i_sync_adapter.dart';
import '../../../data/datasources/interfaces/i_itinerary_local_data_source.dart';
import '../../../data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import '../../../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../../database/app_database.dart';
import 'base_sync_adapter.dart';

/// 行程節點（C 模式）同步適配器。
///
/// scope 為 tripId：每個本地行程各自拉取其節點。
@lazySingleton
class ItinerarySyncAdapter extends BaseSyncAdapter<ItineraryItem> {
  final IItineraryLocalDataSource _localDataSource;
  final IItineraryRemoteDataSource _remoteDataSource;
  final ITripLocalDataSource _tripLocalDataSource;

  @override
  final AppDatabase db;

  ItinerarySyncAdapter(this._localDataSource, this._remoteDataSource, this._tripLocalDataSource, this.db);

  @override
  String get tableName => 'itinerary_items_table';

  // ── Push ──
  @override
  Future<List<ItineraryItem>> getLocalItems() => _localDataSource.getAll();

  @override
  Future<IdMigration?> pushOne(ItineraryItem item) async {
    switch (item.syncStatus) {
      case SyncStatus.pendingCreate:
        final remoteItem = await _remoteDataSource.addItem(item.tripId, item);
        if (remoteItem.id != item.id) {
          return IdMigration(tempId: item.id, permanentId: remoteItem.id);
        }
        return null;
      case SyncStatus.pendingUpdate:
      case SyncStatus.conflict:
        await _remoteDataSource.updateItem(item.tripId, item);
        return null;
      case SyncStatus.pendingDelete:
        await _remoteDataSource.deleteItem(item.tripId, item.id);
        await _localDataSource.deleteById(item.id);
        return null;
      default:
        return null;
    }
  }

  @override
  Future<void> migrateLocalId(String oldId, String newId) => _localDataSource.migrateId(oldId, newId);

  // ── Pull ──
  @override
  Future<List<String>> resolveScopes() async {
    final trips = await _tripLocalDataSource.getAllTrips();
    return trips.where((t) => t.syncStatus != SyncStatus.pendingDelete).map((t) => t.id).toList();
  }

  @override
  Future<List<ItineraryItem>> fetchRemote(String scope) => _remoteDataSource.getItinerary(scope);

  @override
  Future<List<ItineraryItem>> getLocalItemsForScope(String scope) async {
    final all = await _localDataSource.getAll();
    return all.where((i) => i.tripId == scope).toList();
  }

  @override
  Future<ItineraryItem?> getLocalById(String id) => _localDataSource.getById(id);

  @override
  Future<void> upsertLocalSynced(ItineraryItem remote, ItineraryItem? local) async {
    final synced = remote.copyWith(syncStatus: SyncStatus.synced);
    if (local == null) {
      await _localDataSource.addItem(synced);
    } else {
      await _localDataSource.updateItem(synced);
    }
  }

  @override
  Future<void> markLocalConflict(ItineraryItem local) =>
      _localDataSource.updateItem(local.copyWith(syncStatus: SyncStatus.conflict));

  @override
  Future<void> deleteLocal(String id) => _localDataSource.deleteById(id);

  @override
  DateTime? timestampOf(ItineraryItem item) => item.updatedAt ?? item.createdAt;
}
