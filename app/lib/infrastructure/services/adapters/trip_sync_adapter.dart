import 'package:injectable/injectable.dart';
import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/interfaces/i_sync_adapter.dart';
import '../../../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../../../data/datasources/interfaces/i_trip_remote_data_source.dart';
import '../../database/app_database.dart';
import 'base_sync_adapter.dart';

/// 行程本體（C 模式）同步適配器。
///
/// 與裝備／節點不同，行程一次拉取使用者的所有遠端行程（單一 scope），
/// 並於合併時保留本地的 `isActive` 狀態。
@lazySingleton
class TripSyncAdapter extends BaseSyncAdapter<Trip> {
  /// 行程採整批拉取，scope 內容不影響結果，僅作單次迭代用。
  static const String _allScope = '__all_trips__';

  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  @override
  final AppDatabase db;

  TripSyncAdapter(this._localDataSource, this._remoteDataSource, this.db);

  @override
  String get tableName => 'trips_table';

  // ── Push ──
  @override
  Future<List<Trip>> getLocalItems() => _localDataSource.getAllTrips();

  @override
  Future<IdMigration?> pushOne(Trip item) async {
    switch (item.syncStatus) {
      case SyncStatus.pendingCreate:
      case SyncStatus.pendingUpdate:
      case SyncStatus.conflict:
        final result = await _remoteDataSource.uploadTrip(item);
        if (result is Success<String, Exception>) {
          final remoteId = result.value;
          if (item.syncStatus == SyncStatus.pendingCreate && remoteId != item.id) {
            return IdMigration(tempId: item.id, permanentId: remoteId);
          }
          return null;
        }
        throw (result as Failure<String, Exception>).exception;
      case SyncStatus.pendingDelete:
        final result = await _remoteDataSource.deleteTrip(item.id);
        if (result is Success<void, Exception>) {
          await _localDataSource.deleteTrip(item.id);
          return null;
        }
        throw (result as Failure<void, Exception>).exception;
      default:
        return null;
    }
  }

  @override
  Future<void> migrateLocalId(String oldId, String newId) => _localDataSource.migrateTripId(oldId, newId);

  // ── Pull ──
  @override
  Future<List<String>> resolveScopes() async => const [_allScope];

  @override
  Future<List<Trip>> fetchRemote(String scope) async {
    final result = await _remoteDataSource.getRemoteTrips();
    if (result is Success<PaginatedList<Trip>, Exception>) {
      return result.value.items;
    }
    throw (result as Failure<PaginatedList<Trip>, Exception>).exception;
  }

  @override
  Future<List<Trip>> getLocalItemsForScope(String scope) => _localDataSource.getAllTrips();

  @override
  Future<Trip?> getLocalById(String id) => _localDataSource.getTripById(id);

  @override
  Future<void> upsertLocalSynced(Trip remote, Trip? local) async {
    if (local == null) {
      await _localDataSource.addTrip(remote.copyWith(syncStatus: SyncStatus.synced));
    } else {
      // 保留本地的 isActive 狀態
      await _localDataSource.updateTrip(remote.copyWith(isActive: local.isActive, syncStatus: SyncStatus.synced));
    }
  }

  @override
  Future<void> markLocalConflict(Trip local) =>
      _localDataSource.updateTrip(local.copyWith(syncStatus: SyncStatus.conflict));

  @override
  Future<void> deleteLocal(String id) => _localDataSource.deleteTrip(id);

  /// 行程須「曾上傳過」(`cloudSyncedAt != null`) 才視為遠端刪除。
  @override
  bool wasEverSynced(Trip local) => local.cloudSyncedAt != null;
}
