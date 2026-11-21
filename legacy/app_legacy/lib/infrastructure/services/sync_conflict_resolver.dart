import '../../domain/enums/sync_status.dart';
import '../../core/offline_config.dart';

class SyncConflictResolver {
  SyncConflictResolver._();

  static bool hasPendingChanges(SyncStatus status) =>
      status == SyncStatus.pendingUpdate || status == SyncStatus.conflict;

  static bool remoteIsNewer(DateTime? localTime, DateTime? remoteTime) {
    final local = localTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final remote = remoteTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final diff = remote.difference(local).abs().inSeconds;
    return remote.isAfter(local) && diff > OfflineConfig.conflictToleranceSeconds;
  }
}
