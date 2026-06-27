import 'package:injectable/injectable.dart';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/interfaces/i_sync_adapter.dart';
import '../../../data/datasources/interfaces/i_gear_local_data_source.dart';
import '../../../data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import '../../../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../../database/app_database.dart';
import 'base_sync_adapter.dart';

/// 裝備（C 模式）同步適配器。
///
/// scope 為 tripId：每個本地行程各自拉取其裝備。
@lazySingleton
class GearSyncAdapter extends BaseSyncAdapter<GearItem> {
  final IGearLocalDataSource _localDataSource;
  final ITripGearRemoteDataSource _remoteDataSource;
  final ITripLocalDataSource _tripLocalDataSource;

  @override
  final AppDatabase db;

  GearSyncAdapter(this._localDataSource, this._remoteDataSource, this._tripLocalDataSource, this.db);

  @override
  String get tableName => 'gear_items_table';

  // ── Push ──
  @override
  Future<List<GearItem>> getLocalItems() => _localDataSource.getAll();

  @override
  Future<IdMigration?> pushOne(GearItem item) async {
    switch (item.syncStatus) {
      case SyncStatus.pendingCreate:
        final remoteItem = await _remoteDataSource.addTripGear(item.tripId, item);
        if (remoteItem.id != item.id) {
          return IdMigration(tempId: item.id, permanentId: remoteItem.id);
        }
        return null;
      case SyncStatus.pendingUpdate:
      case SyncStatus.conflict:
        await _remoteDataSource.updateTripGear(item.tripId, item);
        return null;
      case SyncStatus.pendingDelete:
        await _remoteDataSource.deleteTripGear(item.tripId, item.id);
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
  Future<List<GearItem>> fetchRemote(String scope) => _remoteDataSource.getTripGear(scope);

  @override
  Future<List<GearItem>> getLocalItemsForScope(String scope) async {
    final all = await _localDataSource.getAll();
    return all.where((i) => i.tripId == scope).toList();
  }

  @override
  Future<GearItem?> getLocalById(String id) => _localDataSource.getById(id);

  @override
  Future<void> upsertLocalSynced(GearItem remote, GearItem? local) async {
    final synced = remote.copyWith(syncStatus: SyncStatus.synced);
    if (local == null) {
      await _localDataSource.addItem(synced);
    } else {
      await _localDataSource.updateItem(synced);
    }
  }

  @override
  Future<void> markLocalConflict(GearItem local) =>
      _localDataSource.updateItem(local.copyWith(syncStatus: SyncStatus.conflict));

  @override
  Future<void> deleteLocal(String id) => _localDataSource.deleteById(id);

  @override
  DateTime? timestampOf(GearItem item) => item.updatedAt ?? item.createdAt;
}
