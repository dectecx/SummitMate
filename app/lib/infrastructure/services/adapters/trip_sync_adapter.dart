import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../domain/enums/sync_status.dart';
import '../../../../domain/interfaces/i_sync_adapter.dart';
import '../../../../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../../../../data/datasources/interfaces/i_trip_remote_data_source.dart';
import '../../../../core/models/paginated_list.dart';
import '../sync_conflict_resolver.dart';

@lazySingleton
class TripSyncAdapter implements ISyncAdapter<Trip> {
  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  TripSyncAdapter(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<IdMigration?, Exception>> pushItem(Trip item, SyncStatus status) async {
    try {
      if (status == SyncStatus.pendingCreate || status == SyncStatus.pendingUpdate || status == SyncStatus.conflict) {
        final result = await _remoteDataSource.uploadTrip(item);
        if (result is Success<String, Exception>) {
          final remoteId = result.value;
          if (status == SyncStatus.pendingCreate && remoteId != item.id) {
            return Success(IdMigration(tempId: item.id, permanentId: remoteId));
          }
          return const Success(null);
        } else {
          return Failure((result as Failure<String, Exception>).exception);
        }
      } else if (status == SyncStatus.pendingDelete) {
        final result = await _remoteDataSource.deleteTrip(item.id);
        if (result is Success<void, Exception>) {
          await _localDataSource.deleteTrip(item.id);
          return const Success(null);
        } else {
          return Failure((result as Failure<void, Exception>).exception);
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<SyncMergeResult, Exception>> pullAndMerge(String scopeId) async {
    try {
      final result = await _remoteDataSource.getRemoteTrips();
      if (result is Failure<PaginatedList<Trip>, Exception>) {
        return Failure(result.exception);
      }

      final paginatedList = (result as Success<PaginatedList<Trip>, Exception>).value;
      final remoteTrips = paginatedList.items;

      // 建立遠端 ID Set，用於偵測「遠端已刪除」場景
      final remoteIds = remoteTrips.map((t) => t.id).toSet();

      int pulledCount = remoteTrips.length;
      int conflictCount = 0;
      int localWinsCount = 0;
      int remoteWinsCount = 0;

      // 偵測遠端已刪除：本地有 pending 資料但遠端 ID 集合中找不到
      final allLocalTrips = await _localDataSource.getAllTrips();
      for (final localTrip in allLocalTrips) {
        final hasPendingChanges = SyncConflictResolver.hasPendingChanges(localTrip.syncStatus);
        final isNotInRemote = !remoteIds.contains(localTrip.id);
        final isCloudReady = localTrip.cloudSyncedAt != null; // 曾經上傳過才算「遠端刪除」

        if (hasPendingChanges && isNotInRemote && isCloudReady) {
          // 遠端已刪除此行程，清除本地資料（遠端刪除優先）
          await _localDataSource.deleteTrip(localTrip.id);
          conflictCount++;
        }
      }

      for (final remoteTrip in remoteTrips) {
        final localTrip = await _localDataSource.getTripById(remoteTrip.id);
        if (localTrip == null) {
          // 本地沒有，直接寫入
          await _localDataSource.addTrip(remoteTrip.copyWith(syncStatus: SyncStatus.synced));
          remoteWinsCount++;
        } else {
          if (localTrip.syncStatus == SyncStatus.synced) {
            // 本地已同步，直接以遠端更新（非衝突，正常覆蓋）
            await _localDataSource.updateTrip(remoteTrip.copyWith(syncStatus: SyncStatus.synced));
            remoteWinsCount++;
          } else {
            // 本地有未同步變更，發生衝突
            conflictCount++;
            final remoteIsNewer = SyncConflictResolver.remoteIsNewer(localTrip.updatedAt, remoteTrip.updatedAt);

            if (remoteIsNewer) {
              // 遠端明顯較新（超過容忍閾值），遠端勝出
              await _localDataSource.updateTrip(remoteTrip.copyWith(syncStatus: SyncStatus.synced));
              remoteWinsCount++;
            } else {
              // 本地較新或差距在容忍閾值內，本地勝出，標記為 conflict 等待下次 Push
              await _localDataSource.updateTrip(localTrip.copyWith(syncStatus: SyncStatus.conflict));
              localWinsCount++;
            }
          }
        }
      }

      return Success(
        SyncMergeResult(
          pulledCount: pulledCount,
          conflictCount: conflictCount,
          localWinsCount: localWinsCount,
          remoteWinsCount: remoteWinsCount,
        ),
      );
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
