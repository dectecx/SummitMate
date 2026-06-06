import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import 'package:summitmate/domain/entities/itinerary_item.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/domain/interfaces/i_sync_adapter.dart';
import 'package:summitmate/infrastructure/services/adapters/itinerary_sync_adapter.dart';

class MockItineraryLocalDataSource extends Mock implements IItineraryLocalDataSource {}

class MockItineraryRemoteDataSource extends Mock implements IItineraryRemoteDataSource {}

class FakeItineraryItem extends Fake implements ItineraryItem {}

void main() {
  late ItinerarySyncAdapter adapter;
  late MockItineraryLocalDataSource mockLocal;
  late MockItineraryRemoteDataSource mockRemote;

  setUpAll(() {
    registerFallbackValue(FakeItineraryItem());
  });

  setUp(() {
    mockLocal = MockItineraryLocalDataSource();
    mockRemote = MockItineraryRemoteDataSource();
    adapter = ItinerarySyncAdapter(mockLocal, mockRemote);
  });

  final defaultItem = ItineraryItem(
    id: 'item1',
    tripId: 'trip1',
    day: 'Day 1',
    name: 'Camp 1',
    estTime: '10:00',
    syncStatus: SyncStatus.synced,
    createdAt: DateTime(2026, 6, 6),
    updatedAt: DateTime(2026, 6, 6, 12, 0, 0),
  );

  group('ItinerarySyncAdapter - pushItem', () {
    test('Given pendingCreate, When calling pushItem, Then it should add item in remote', () async {
      when(() => mockRemote.addItem(any(), any())).thenAnswer((_) async => defaultItem);

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingCreate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.addItem('trip1', defaultItem)).called(1);
    });

    test('Given remote ID differs in pendingCreate, When calling pushItem, Then it should migrate ID', () async {
      final remoteItem = defaultItem.copyWith(id: 'remote-item-id');
      when(() => mockRemote.addItem(any(), any())).thenAnswer((_) async => remoteItem);

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingCreate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      final migration = (result as Success<IdMigration?, Exception>).value;
      expect(migration?.tempId, 'item1');
      expect(migration?.permanentId, 'remote-item-id');
    });

    test('Given pendingUpdate/conflict, When calling pushItem, Then it should update item in remote', () async {
      when(() => mockRemote.updateItem(any(), any())).thenAnswer((_) async => defaultItem);

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingUpdate);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.updateItem('trip1', defaultItem)).called(1);
    });

    test('Given pendingDelete, When calling pushItem, Then it should delete item from remote and local', () async {
      when(() => mockRemote.deleteItem(any(), any())).thenAnswer((_) async {});
      when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

      final result = await adapter.pushItem(defaultItem, SyncStatus.pendingDelete);

      expect(result, isA<Success<IdMigration?, Exception>>());
      verify(() => mockRemote.deleteItem('trip1', 'item1')).called(1);
      verify(() => mockLocal.deleteById('item1')).called(1);
    });
  });

  group('ItinerarySyncAdapter - pullAndMerge', () {
    test('Given not exists in local, When calling pullAndMerge, Then it should add item to local', () async {
      when(() => mockRemote.getItinerary(any())).thenAnswer((_) async => [defaultItem]);
      when(() => mockLocal.getAll()).thenAnswer((_) async => []);
      when(() => mockLocal.getById(any())).thenAnswer((_) async => null);
      when(() => mockLocal.addItem(any())).thenAnswer((_) async {});

      final result = await adapter.pullAndMerge('trip1');

      expect(result, isA<Success<SyncMergeResult, Exception>>());
      final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
      expect(mergeResult.pulledCount, 1);
      expect(mergeResult.remoteWinsCount, 1);
      verify(() => mockLocal.addItem(any())).called(1);
    });

    test(
      'Given remote deleted and local has pending changes (wasEverSynced), When calling pullAndMerge, Then it should delete local item',
      () async {
        final localItem = defaultItem.copyWith(syncStatus: SyncStatus.pendingUpdate);
        when(() => mockRemote.getItinerary(any())).thenAnswer((_) async => []);
        when(() => mockLocal.getAll()).thenAnswer((_) async => [localItem]);
        when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

        final result = await adapter.pullAndMerge('trip1');

        expect(result, isA<Success<SyncMergeResult, Exception>>());
        final mergeResult = (result as Success<SyncMergeResult, Exception>).value;
        expect(mergeResult.conflictCount, 1);
        verify(() => mockLocal.deleteById('item1')).called(1);
      },
    );

    test(
      'Given local is synced and remote is updated, When calling pullAndMerge, Then it should overwrite local',
      () async {
        final remoteItem = defaultItem.copyWith(name: 'Remote updated', updatedAt: DateTime(2026, 6, 6, 12, 1, 0));
        when(() => mockRemote.getItinerary(any())).thenAnswer((_) async => [remoteItem]);
        when(() => mockLocal.getAll()).thenAnswer((_) async => [defaultItem]);
        when(() => mockLocal.getById('item1')).thenAnswer((_) async => defaultItem);
        when(() => mockLocal.updateItem(any())).thenAnswer((_) async {});

        final result = await adapter.pullAndMerge('trip1');

        expect(result, isA<Success<SyncMergeResult, Exception>>());
        verify(() => mockLocal.updateItem(any())).called(1);
      },
    );
  });
}
