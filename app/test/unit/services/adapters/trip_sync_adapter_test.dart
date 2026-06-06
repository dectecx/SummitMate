import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/entities/trip.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/domain/interfaces/i_sync_adapter.dart';
import 'package:summitmate/infrastructure/services/adapters/trip_sync_adapter.dart';

class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}
class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}
class FakeTrip extends Fake implements Trip {}

void main() {
  late TripSyncAdapter adapter;
  late MockTripLocalDataSource mockLocal;
  late MockTripRemoteDataSource mockRemote;

  setUpAll(() {
    registerFallbackValue(FakeTrip());
  });

  setUp(() {
    mockLocal = MockTripLocalDataSource();
    mockRemote = MockTripRemoteDataSource();
    adapter = TripSyncAdapter(mockLocal, mockRemote);
  });

  final defaultTrip = Trip(
    id: '1',
    userId: 'user1',
    name: 'Trip 1',
    startDate: DateTime(2026, 6, 6),
    createdAt: DateTime(2026, 6, 6),
    createdBy: 'user1',
    updatedAt: DateTime(2026, 6, 6, 12, 0, 0),
    updatedBy: 'user1',
    syncStatus: SyncStatus.synced,
  );

  group('TripSyncAdapter - pushItem', () {
    test('should upload trip when status is pendingCreate/pendingUpdate/conflict', () async {
      when(() => mockRemote.uploadTrip(any())).thenAnswer((_) async => const Success('1'));

      final result = await adapter.pushItem(defaultTrip, SyncStatus.pendingCreate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.uploadTrip(any())).called(1);
    });

    test('should migrate ID when remote ID differs in pendingCreate', () async {
      when(() => mockRemote.uploadTrip(any())).thenAnswer((_) async => const Success('remote-id-123'));

      final result = await adapter.pushItem(defaultTrip, SyncStatus.pendingCreate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      final migration = (result as Success<IdMigration?, Exception>).value;
      expect(migration?.tempId, '1');
      expect(migration?.permanentId, 'remote-id-123');
    });

    test('should delete trip when status is pendingDelete', () async {
      when(() => mockRemote.deleteTrip(any())).thenAnswer((_) async => const Success(null));
      when(() => mockLocal.deleteTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pushItem(defaultTrip, SyncStatus.pendingDelete);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.deleteTrip('1')).called(1);
      verify(() => mockLocal.deleteTrip('1')).called(1);
    });
  });

  group('TripSyncAdapter - pullAndMerge', () {
    test('should add trip to local if not exists in local', () async {
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Trip');
      when(() => mockRemote.getRemoteTrips()).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => []);
      when(() => mockLocal.getTripById(any())).thenAnswer((_) async => null);
      when(() => mockLocal.addTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullAndMerge('scopeId');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.pulledCount, 1);
      expect(mergeResult.remoteWinsCount, 1);
      expect(mergeResult.localWinsCount, 0);
      expect(mergeResult.conflictCount, 0);

      verify(() => mockLocal.addTrip(any())).called(1);
    });

    test('should perform local delete if remote deleted and local has pending changes (wasEverSynced)', () async {
      final localTrip = defaultTrip.copyWith(syncStatus: SyncStatus.pendingUpdate, cloudSyncedAt: DateTime.now());
      when(() => mockRemote.getRemoteTrips()).thenAnswer((_) async => Success(PaginatedList(items: [], total: 0, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [localTrip]);
      when(() => mockLocal.deleteTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullAndMerge('scopeId');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.conflictCount, 1);
      verify(() => mockLocal.deleteTrip('1')).called(1);
    });

    test('should overwrite local if local is synced and remote is updated', () async {
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Updated', updatedAt: DateTime(2026, 6, 6, 12, 1, 0));
      when(() => mockRemote.getRemoteTrips()).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [defaultTrip]);
      when(() => mockLocal.getTripById('1')).thenAnswer((_) async => defaultTrip);
      when(() => mockLocal.updateTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullAndMerge('scopeId');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.remoteWinsCount, 1);
      verify(() => mockLocal.updateTrip(any())).called(1);
    });

    test('should resolve remote-wins conflict if local is pendingUpdate and remote is newer (> 5s difference)', () async {
      final localTrip = defaultTrip.copyWith(syncStatus: SyncStatus.pendingUpdate, updatedAt: DateTime(2026, 6, 6, 12, 0, 0));
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Newer', updatedAt: DateTime(2026, 6, 6, 12, 0, 10)); // 10s newer
      
      when(() => mockRemote.getRemoteTrips()).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [localTrip]);
      when(() => mockLocal.getTripById('1')).thenAnswer((_) async => localTrip);
      when(() => mockLocal.updateTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullAndMerge('scopeId');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.conflictCount, 1);
      expect(mergeResult.remoteWinsCount, 1);
      expect(mergeResult.localWinsCount, 0);

      verify(() => mockLocal.updateTrip(any())).called(1);
    });

    test('should resolve local-wins conflict if local is pendingUpdate and remote is older or within tolerance window (<= 5s difference)', () async {
      final localTrip = defaultTrip.copyWith(syncStatus: SyncStatus.pendingUpdate, updatedAt: DateTime(2026, 6, 6, 12, 0, 0));
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Close', updatedAt: DateTime(2026, 6, 6, 12, 0, 4)); // 4s newer (within tolerance)
      
      when(() => mockRemote.getRemoteTrips()).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [localTrip]);
      when(() => mockLocal.getTripById('1')).thenAnswer((_) async => localTrip);
      when(() => mockLocal.updateTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullAndMerge('scopeId');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.conflictCount, 1);
      expect(mergeResult.localWinsCount, 1);
      expect(mergeResult.remoteWinsCount, 0);

      verify(() => mockLocal.updateTrip(any())).called(1);
    });
  });
}
