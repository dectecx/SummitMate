import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/domain/entities/itinerary_item.dart';
import 'package:summitmate/domain/entities/trip.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/adapters/itinerary_sync_adapter.dart';

class MockItineraryLocalDataSource extends Mock implements IItineraryLocalDataSource {}

class MockItineraryRemoteDataSource extends Mock implements IItineraryRemoteDataSource {}

class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeItineraryItem extends Fake implements ItineraryItem {}

void main() {
  late ItinerarySyncAdapter adapter;
  late MockItineraryLocalDataSource mockLocal;
  late MockItineraryRemoteDataSource mockRemote;
  late MockTripLocalDataSource mockTripLocal;
  late MockAppDatabase mockDb;

  setUpAll(() {
    registerFallbackValue(FakeItineraryItem());
  });

  setUp(() {
    mockLocal = MockItineraryLocalDataSource();
    mockRemote = MockItineraryRemoteDataSource();
    mockTripLocal = MockTripLocalDataSource();
    mockDb = MockAppDatabase();
    adapter = ItinerarySyncAdapter(mockLocal, mockRemote, mockTripLocal, mockDb);
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

  final scopeTrip = Trip(
    id: 'trip1',
    userId: 'u1',
    name: 'Trip 1',
    startDate: DateTime(2026, 6, 6),
    createdAt: DateTime(2026, 6, 6),
    createdBy: 'u1',
    updatedAt: DateTime(2026, 6, 6),
    updatedBy: 'u1',
    syncStatus: SyncStatus.synced,
  );

  group('ItinerarySyncAdapter - pushOne', () {
    test('Given pendingCreate with same id, When pushOne, Then it adds remote item and no migration', () async {
      when(() => mockRemote.addItem(any(), any())).thenAnswer((_) async => defaultItem);

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingCreate));

      expect(migration, isNull);
      verify(() => mockRemote.addItem('trip1', any())).called(1);
    });

    test('Given remote id differs in pendingCreate, When pushOne, Then it returns an IdMigration', () async {
      when(() => mockRemote.addItem(any(), any())).thenAnswer((_) async => defaultItem.copyWith(id: 'remote-item-id'));

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingCreate));

      expect(migration?.tempId, 'item1');
      expect(migration?.permanentId, 'remote-item-id');
    });

    test('Given pendingUpdate, When pushOne, Then it updates remote item', () async {
      when(() => mockRemote.updateItem(any(), any())).thenAnswer((_) async => defaultItem);

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingUpdate));

      expect(migration, isNull);
      verify(() => mockRemote.updateItem('trip1', any())).called(1);
    });

    test('Given pendingDelete, When pushOne, Then it deletes remote and local item', () async {
      when(() => mockRemote.deleteItem(any(), any())).thenAnswer((_) async {});
      when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingDelete));

      expect(migration, isNull);
      verify(() => mockRemote.deleteItem('trip1', 'item1')).called(1);
      verify(() => mockLocal.deleteById('item1')).called(1);
    });
  });

  group('ItinerarySyncAdapter - pullRemote', () {
    test('Given not exists in local, When pullRemote, Then it adds item to local', () async {
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [scopeTrip]);
      when(() => mockRemote.getItinerary('trip1')).thenAnswer((_) async => [defaultItem]);
      when(() => mockLocal.getAll()).thenAnswer((_) async => []);
      when(() => mockLocal.getById(any())).thenAnswer((_) async => null);
      when(() => mockLocal.addItem(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.pulledCount, 1);
      expect(result.remoteWinsCount, 1);
      verify(() => mockLocal.addItem(any())).called(1);
    });

    test('Given remote deleted and local pending (wasEverSynced), When pullRemote, Then it deletes local item', () async {
      final localItem = defaultItem.copyWith(syncStatus: SyncStatus.pendingUpdate);
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [scopeTrip]);
      when(() => mockRemote.getItinerary('trip1')).thenAnswer((_) async => []);
      when(() => mockLocal.getAll()).thenAnswer((_) async => [localItem]);
      when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.conflictCount, 1);
      verify(() => mockLocal.deleteById('item1')).called(1);
    });

    test('Given local synced and remote updated, When pullRemote, Then it overwrites local', () async {
      final remoteItem = defaultItem.copyWith(name: 'Remote updated', updatedAt: DateTime(2026, 6, 6, 12, 1, 0));
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [scopeTrip]);
      when(() => mockRemote.getItinerary('trip1')).thenAnswer((_) async => [remoteItem]);
      when(() => mockLocal.getAll()).thenAnswer((_) async => [defaultItem]);
      when(() => mockLocal.getById('item1')).thenAnswer((_) async => defaultItem);
      when(() => mockLocal.updateItem(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.remoteWinsCount, 1);
      verify(() => mockLocal.updateItem(any())).called(1);
    });
  });
}
