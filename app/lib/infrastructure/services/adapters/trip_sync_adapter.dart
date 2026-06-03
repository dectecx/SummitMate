import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../domain/enums/sync_status.dart';
import '../../../../domain/interfaces/i_sync_adapter.dart';
import '../../../../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../../../../data/datasources/interfaces/i_trip_remote_data_source.dart';
import '../../../../core/models/paginated_list.dart';

@lazySingleton
class TripSyncAdapter implements ISyncAdapter<Trip> {
  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  TripSyncAdapter(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<IdMigration?, Exception>> pushItem(Trip item, SyncStatus status) async {
    try {
      if (status == SyncStatus.pendingCreate || status == SyncStatus.pendingUpdate) {
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
      // 呼叫 getRemoteTrips() 獲取所有遠端行程
      final result = await _remoteDataSource.getRemoteTrips();
      if (result is Failure<PaginatedList<Trip>, Exception>) {
        return Failure(result.exception);
      }

      final paginatedList = (result as Success<PaginatedList<Trip>, Exception>).value;
      final remoteTrips = paginatedList.items;

      int pulledCount = remoteTrips.length;
      int conflictCount = 0;
      int localWinsCount = 0;
      int remoteWinsCount = 0;

      for (final remoteTrip in remoteTrips) {
        final localTrip = await _localDataSource.getTripById(remoteTrip.id);
        if (localTrip == null) {
          // 本地沒有，直接寫入 (寫入時標記為 synced)
          await _localDataSource.addTrip(remoteTrip.copyWith(syncStatus: SyncStatus.synced));
          remoteWinsCount++;
        } else {
          // 本地存在，比對 updatedAt 進行衝突解決 (LWW)
          if (localTrip.syncStatus == SyncStatus.synced) {
            // 本地也是 synced，直接以遠端更新本地
            await _localDataSource.updateTrip(remoteTrip.copyWith(syncStatus: SyncStatus.synced));
            remoteWinsCount++;
          } else {
            // 本地有未同步變更，發生衝突
            conflictCount++;
            if (remoteTrip.updatedAt.isAfter(localTrip.updatedAt)) {
              // 遠端較新，遠端勝出
              await _localDataSource.updateTrip(remoteTrip.copyWith(syncStatus: SyncStatus.synced));
              remoteWinsCount++;
            } else {
              // 本地較新或相同，本地勝出 (保留本地 status，不覆蓋)
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
