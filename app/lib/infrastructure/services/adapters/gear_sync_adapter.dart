import 'package:injectable/injectable.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/gear_item.dart';
import '../../../../domain/enums/sync_status.dart';
import '../../../../domain/interfaces/i_sync_adapter.dart';
import '../../../../data/datasources/interfaces/i_gear_local_data_source.dart';
import '../../../../data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import '../sync_conflict_resolver.dart';

@lazySingleton
class GearSyncAdapter implements ISyncAdapter<GearItem> {
  final IGearLocalDataSource _localDataSource;
  final ITripGearRemoteDataSource _remoteDataSource;

  GearSyncAdapter(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<IdMigration?, Exception>> pushItem(GearItem item, SyncStatus status) async {
    try {
      if (status == SyncStatus.pendingCreate) {
        final remoteItem = await _remoteDataSource.addTripGear(item.tripId, item);
        if (remoteItem.id != item.id) {
          return Success(IdMigration(tempId: item.id, permanentId: remoteItem.id));
        }
        return const Success(null);
      } else if (status == SyncStatus.pendingUpdate || status == SyncStatus.conflict) {
        await _remoteDataSource.updateTripGear(item.tripId, item);
        return const Success(null);
      } else if (status == SyncStatus.pendingDelete) {
        await _remoteDataSource.deleteTripGear(item.tripId, item.id);
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
      final remoteItems = await _remoteDataSource.getTripGear(scopeId);

      // 建立遠端 ID Set，用於偵測「遠端已刪除」場景
      final remoteIds = remoteItems.map((i) => i.id).toSet();

      int pulledCount = remoteItems.length;
      int conflictCount = 0;
      int localWinsCount = 0;
      int remoteWinsCount = 0;

      // 偵測遠端已刪除：本地有 pending 資料但遠端 ID 集合中找不到
      final allLocalItems = await _localDataSource.getAll();
      final scopeItems = allLocalItems.where((i) => i.tripId == scopeId).toList();
      for (final localItem in scopeItems) {
        final hasPendingChanges = SyncConflictResolver.hasPendingChanges(localItem.syncStatus);
        final isNotInRemote = !remoteIds.contains(localItem.id);
        // 曾被成功推送過才算「遠端刪除」（pendingCreate 本地才有的不算）
        final wasEverSynced = localItem.syncStatus != SyncStatus.pendingCreate;

        if (hasPendingChanges && isNotInRemote && wasEverSynced) {
          // 遠端已刪除此裝備，清除本地資料（遠端刪除優先）
          await _localDataSource.deleteById(localItem.id);
          conflictCount++;
        }
      }

      for (final remoteItem in remoteItems) {
        final localItem = await _localDataSource.getById(remoteItem.id);
        if (localItem == null) {
          // 本地沒有，直接寫入
          await _localDataSource.addItem(remoteItem.copyWith(syncStatus: SyncStatus.synced));
          remoteWinsCount++;
        } else {
          if (localItem.syncStatus == SyncStatus.synced) {
            // 本地已同步，直接以遠端更新（非衝突，正常覆蓋）
            await _localDataSource.updateItem(remoteItem.copyWith(syncStatus: SyncStatus.synced));
            remoteWinsCount++;
          } else {
            // 本地有未同步變更，發生衝突
            conflictCount++;
            final localTime = localItem.updatedAt ?? localItem.createdAt;
            final remoteTime = remoteItem.updatedAt ?? remoteItem.createdAt;
            final remoteIsNewer = SyncConflictResolver.remoteIsNewer(localTime, remoteTime);

            if (remoteIsNewer) {
              // 遠端明顯較新（超過容忍閾值），遠端勝出
              await _localDataSource.updateItem(remoteItem.copyWith(syncStatus: SyncStatus.synced));
              remoteWinsCount++;
            } else {
              // 本地較新或差距在容忍閾值內，本地勝出，標記為 conflict 等待下次 Push
              await _localDataSource.updateItem(localItem.copyWith(syncStatus: SyncStatus.conflict));
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
