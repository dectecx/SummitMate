import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/infrastructure/services/sync_conflict_resolver.dart';

void main() {
  group('SyncConflictResolver', () {
    group('hasPendingChanges', () {
      test('should return true for pendingUpdate and conflict', () {
        expect(SyncConflictResolver.hasPendingChanges(SyncStatus.pendingUpdate), isTrue);
        expect(SyncConflictResolver.hasPendingChanges(SyncStatus.conflict), isTrue);
      });

      test('should return false for other statuses', () {
        expect(SyncConflictResolver.hasPendingChanges(SyncStatus.synced), isFalse);
        expect(SyncConflictResolver.hasPendingChanges(SyncStatus.pendingCreate), isFalse);
        expect(SyncConflictResolver.hasPendingChanges(SyncStatus.pendingDelete), isFalse);
      });
    });

    group('remoteIsNewer', () {
      test('should return true when remote is newer and difference is greater than tolerance', () {
        final local = DateTime(2026, 6, 6, 12, 0, 0);
        // Tolerance is 5 seconds. Remote is 6 seconds newer.
        final remote = DateTime(2026, 6, 6, 12, 0, 6);
        expect(SyncConflictResolver.remoteIsNewer(local, remote), isTrue);
      });

      test('should return false when remote is newer but difference is within tolerance', () {
        final local = DateTime(2026, 6, 6, 12, 0, 0);
        // Remote is 5 seconds newer (exactly tolerance).
        final remote = DateTime(2026, 6, 6, 12, 0, 5);
        expect(SyncConflictResolver.remoteIsNewer(local, remote), isFalse);
      });

      test('should return false when remote is older', () {
        final local = DateTime(2026, 6, 6, 12, 0, 10);
        final remote = DateTime(2026, 6, 6, 12, 0, 0);
        expect(SyncConflictResolver.remoteIsNewer(local, remote), isFalse);
      });

      test('should handle nullable local or remote time by falling back to epoch 0', () {
        final local = DateTime(2026, 6, 6, 12, 0, 0);
        // remote is null -> epoch 0 -> older than local
        expect(SyncConflictResolver.remoteIsNewer(local, null), isFalse);
        
        // local is null -> epoch 0 -> remote is newer and diff > 5s
        expect(SyncConflictResolver.remoteIsNewer(null, local), isTrue);
      });
    });
  });
}
