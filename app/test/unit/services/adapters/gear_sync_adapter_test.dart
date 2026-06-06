import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import 'package:summitmate/domain/entities/gear_item.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/domain/interfaces/i_sync_adapter.dart';
import 'package:summitmate/infrastructure/services/adapters/gear_sync_adapter.dart';

class MockGearLocalDataSource extends Mock implements IGearLocalDataSource {}

class MockTripGearRemoteDataSource extends Mock implements ITripGearRemoteDataSource {}

class FakeGearItem extends Fake implements GearItem {}

void main() {
  late GearSyncAdapter adapter;
  late MockGearLocalDataSource mockLocal;
  late MockTripGearRemoteDataSource mockRemote;

  setUpAll(() {
    registerFallbackValue(FakeGearItem());
  });

  setUp(() {
    mockLocal = MockGearLocalDataSource();
    mockRemote = MockTripGearRemoteDataSource();
    adapter = GearSyncAdapter(mockLocal, mockRemote);
  });

  final defaultItem = GearItem(
    id: 'gear1',
    tripId: 'trip1',
    name: 'Sleeping Bag',
    category: 'Sleep',
    quantity: 1,
    weight: 0.0,
    syncStatus: SyncStatus.synced,
    createdAt: DateTime(2026, 6, 6),
    updatedAt: DateTime(2026, 6, 6, 12, 0, 0),
  );

  group('GearSyncAdapter - pushItem', () {
    test('Given pendingCreate, When calling pushItem, Then it should add gear in remote', () async {
      when(() => mockRemote.addTripGear(any(), any())).thenAnswer((_) async => defaultItem);

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingCreate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.addTripGear('trip1', defaultItem)).called(1);
    });

    test('Given remote ID differs in pendingCreate, When calling pushItem, Then it should migrate ID', () async {
      final remoteItem = defaultItem.copyWith(id: 'remote-gear-id');
      when(() => mockRemote.addTripGear(any(), any())).thenAnswer((_) async => remoteItem);

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingCreate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      final migration = (result as Success<IdMigration?, Exception>).value;
      expect(migration?.tempId, 'gear1');
      expect(migration?.permanentId, 'remote-gear-id');
    });

    test('Given pendingUpdate/conflict, When calling pushItem, Then it should update gear in remote', () async {
      when(() => mockRemote.updateTripGear(any(), any())).thenAnswer((_) async => defaultItem);

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingUpdate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.updateTripGear('trip1', defaultItem)).called(1);
    });

    test('Given pendingDelete, When calling pushItem, Then it should delete gear from remote and local', () async {
      when(() => mockRemote.deleteTripGear(any(), any())).thenAnswer((_) async {});
      when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingDelete);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.deleteTripGear('trip1', 'gear1')).called(1);
      verify(() => mockLocal.deleteById('gear1')).called(1);
    });
  });

  group('GearSyncAdapter - pullAndMerge', () {
    test('Given not exists in local, When calling pullAndMerge, Then it should add gear to local', () async {
      when(() => mockRemote.getTripGear(any())).thenAnswer((_) async => [defaultItem]);
      when(() => mockLocal.getAll()).thenAnswer((_) async => []);
      when(() => mockLocal.getById(any())).thenAnswer((_) async => null);
      when(() => mockLocal.addItem(any())).thenAnswer((_) async => 1);

      final result = await adapter.pullAndMerge('trip1');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.pulledCount, 1);
      expect(mergeResult.remoteWinsCount, 1);
      verify(() => mockLocal.addItem(any())).called(1);
    });

    test(
      'Given remote deleted and local has pending changes (wasEverSynced), When calling pullAndMerge, Then it should delete local gear',
      () async {
        final localItem = defaultItem.copyWith(syncStatus: SyncStatus.pendingUpdate);
        when(() => mockRemote.getTripGear(any())).thenAnswer((_) async => []);
        when(() => mockLocal.getAll()).thenAnswer((_) async => [localItem]);
        when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

        final result = await adapter.pullAndMerge('trip1');

        expect(result, isA<Success<SyncMergeResult, Exception>>());
        final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
        expect(mergeResult.conflictCount, 1);
        verify(() => mockLocal.deleteById('gear1')).called(1);
      },
    );

    test(
      'Given local is synced and remote is updated, When calling pullAndMerge, Then it should overwrite local',
      () async {
        final remoteItem = defaultItem.copyWith(name: 'Remote updated', updatedAt: DateTime(2026, 6, 6, 12, 1, 0));
        when(() => mockRemote.getTripGear(any())).thenAnswer((_) async => [remoteItem]);
        when(() => mockLocal.getAll()).thenAnswer((_) async => [defaultItem]);
        when(() => mockLocal.getById('gear1')).thenAnswer((_) async => defaultItem);
        when(() => mockLocal.updateItem(any())).thenAnswer((_) async {});

        final result = await adapter.pullAndMerge('trip1');

        expect(result, isA<Success<SyncMergeResult, Exception>>());
        verify(() => mockLocal.updateItem(any())).called(1);
      },
    );
  });
}
