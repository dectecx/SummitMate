import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/itinerary_item.dart';
import '../../../../domain/enums/sync_status.dart';
import '../../../../domain/interfaces/i_sync_adapter.dart';
import '../../../../data/datasources/interfaces/i_itinerary_local_data_source.dart';
import '../../../../data/datasources/interfaces/i_itinerary_remote_data_source.dart';

@lazySingleton
class ItinerarySyncAdapter implements ISyncAdapter<ItineraryItem> {
  final IItineraryLocalDataSource _localDataSource;
  final IItineraryRemoteDataSource _remoteDataSource;

  ItinerarySyncAdapter(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<IdMigration?, Exception>> pushItem(ItineraryItem item, SyncStatus status) async {
    try {
      if (status == SyncStatus.pendingCreate) {
        final remoteItem = await _remoteDataSource.addItem(item.tripId, item);
        if (remoteItem.id != item.id) {
          return Success(IdMigration(tempId: item.id, permanentId: remoteItem.id));
        }
        return const Success(null);
      } else if (status == SyncStatus.pendingUpdate) {
        await _remoteDataSource.updateItem(item.tripId, item);
        return const Success(null);
      } else if (status == SyncStatus.pendingDelete) {
        await _remoteDataSource.deleteItem(item.tripId, item.id);
        await _localDataSource.deleteById(item.id);
        return const Success(null);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<SyncMergeResult, Exception>> pullAndMerge(String scopeId) async {
    try {
      final remoteItems = await _remoteDataSource.getItinerary(scopeId);

      int pulledCount = remoteItems.length;
      int conflictCount = 0;
      int localWinsCount = 0;
      int remoteWinsCount = 0;

      for (final remoteItem in remoteItems) {
        final localItem = await _localDataSource.getById(remoteItem.id);
        if (localItem == null) {
          // 本地沒有，直接寫入
          await _localDataSource.addItem(remoteItem.copyWith(syncStatus: SyncStatus.synced));
          remoteWinsCount++;
        } else {
          if (localItem.syncStatus == SyncStatus.synced) {
            // 本地為 synced，直接更新本地
            await _localDataSource.updateItem(remoteItem.copyWith(syncStatus: SyncStatus.synced));
            remoteWinsCount++;
          } else {
            // 衝突：本地有未同步變更
            conflictCount++;
            final localTime = localItem.updatedAt ?? localItem.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final remoteTime = remoteItem.updatedAt ?? remoteItem.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

            if (remoteTime.isAfter(localTime)) {
              // 遠端較新
              await _localDataSource.updateItem(remoteItem.copyWith(syncStatus: SyncStatus.synced));
              remoteWinsCount++;
            } else {
              // 本地較新，保留本地
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
