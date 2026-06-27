import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/entities/trip.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/adapters/trip_sync_adapter.dart';

class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeTrip extends Fake implements Trip {}

void main() {
  late TripSyncAdapter adapter;
  late MockTripLocalDataSource mockLocal;
  late MockTripRemoteDataSource mockRemote;
  late MockAppDatabase mockDb;

  setUpAll(() {
    registerFallbackValue(FakeTrip());
  });

  setUp(() {
    mockLocal = MockTripLocalDataSource();
    mockRemote = MockTripRemoteDataSource();
    mockDb = MockAppDatabase();
    adapter = TripSyncAdapter(mockLocal, mockRemote, mockDb);
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

  group('TripSyncAdapter - pushOne', () {
    test('Given pendingCreate/pendingUpdate, When pushOne, Then it uploads trip', () async {
      when(() => mockRemote.uploadTrip(any())).thenAnswer((_) async => const Success('1'));

      final migration = await adapter.pushOne(defaultTrip.copyWith(syncStatus: SyncStatus.pendingUpdate));

      expect(migration, isNull);
      verify(() => mockRemote.uploadTrip(any())).called(1);
    });

    test('Given remote id differs in pendingCreate, When pushOne, Then it returns an IdMigration', () async {
      when(() => mockRemote.uploadTrip(any())).thenAnswer((_) async => const Success('remote-id-123'));

      final migration = await adapter.pushOne(defaultTrip.copyWith(syncStatus: SyncStatus.pendingCreate));

      expect(migration?.tempId, '1');
      expect(migration?.permanentId, 'remote-id-123');
    });

    test('Given pendingDelete, When pushOne, Then it deletes remote and local trip', () async {
      when(() => mockRemote.deleteTrip(any())).thenAnswer((_) async => const Success(null));
      when(() => mockLocal.deleteTrip(any())).thenAnswer((_) async {});

      final migration = await adapter.pushOne(defaultTrip.copyWith(syncStatus: SyncStatus.pendingDelete));

      expect(migration, isNull);
      verify(() => mockRemote.deleteTrip('1')).called(1);
      verify(() => mockLocal.deleteTrip('1')).called(1);
    });

    test('Given upload fails, When pushOne, Then it throws the exception', () async {
      when(() => mockRemote.uploadTrip(any())).thenAnswer((_) async => Failure(Exception('boom')));

      expect(
        () => adapter.pushOne(defaultTrip.copyWith(syncStatus: SyncStatus.pendingCreate)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TripSyncAdapter - pullRemote', () {
    test('Given not exists in local, When pullRemote, Then it adds trip to local', () async {
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Trip');
      when(
        () => mockRemote.getRemoteTrips(),
      ).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => []);
      when(() => mockLocal.getTripById(any())).thenAnswer((_) async => null);
      when(() => mockLocal.addTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.pulledCount, 1);
      expect(result.remoteWinsCount, 1);
      verify(() => mockLocal.addTrip(any())).called(1);
    });

    test('Given remote deleted and local pending (cloudSyncedAt set), When pullRemote, Then it deletes local trip', () async {
      final localTrip = defaultTrip.copyWith(syncStatus: SyncStatus.pendingUpdate, cloudSyncedAt: DateTime.now());
      when(
        () => mockRemote.getRemoteTrips(),
      ).thenAnswer((_) async => Success(PaginatedList(items: [], total: 0, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [localTrip]);
      when(() => mockLocal.deleteTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.conflictCount, 1);
      verify(() => mockLocal.deleteTrip('1')).called(1);
    });

    test('Given local pending and remote newer (>5s), When pullRemote, Then remote wins', () async {
      final localTrip = defaultTrip.copyWith(
        syncStatus: SyncStatus.pendingUpdate,
        updatedAt: DateTime(2026, 6, 6, 12, 0, 0),
      );
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Newer', updatedAt: DateTime(2026, 6, 6, 12, 0, 10));
      when(
        () => mockRemote.getRemoteTrips(),
      ).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [localTrip]);
      when(() => mockLocal.getTripById('1')).thenAnswer((_) async => localTrip);
      when(() => mockLocal.updateTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.conflictCount, 1);
      expect(result.remoteWinsCount, 1);
      verify(() => mockLocal.updateTrip(any())).called(1);
    });

    test('Given local pending and remote within tolerance (<=5s), When pullRemote, Then local wins', () async {
      final localTrip = defaultTrip.copyWith(
        syncStatus: SyncStatus.pendingUpdate,
        updatedAt: DateTime(2026, 6, 6, 12, 0, 0),
      );
      final remoteTrip = defaultTrip.copyWith(name: 'Remote Close', updatedAt: DateTime(2026, 6, 6, 12, 0, 4));
      when(
        () => mockRemote.getRemoteTrips(),
      ).thenAnswer((_) async => Success(PaginatedList(items: [remoteTrip], total: 1, page: 1, hasMore: false)));
      when(() => mockLocal.getAllTrips()).thenAnswer((_) async => [localTrip]);
      when(() => mockLocal.getTripById('1')).thenAnswer((_) async => localTrip);
      when(() => mockLocal.updateTrip(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.conflictCount, 1);
      expect(result.localWinsCount, 1);
      verify(() => mockLocal.updateTrip(any())).called(1);
    });
  });
}
