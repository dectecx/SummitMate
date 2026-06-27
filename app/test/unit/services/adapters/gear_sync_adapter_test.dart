import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/domain/entities/gear_item.dart';
import 'package:summitmate/domain/entities/trip.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/adapters/gear_sync_adapter.dart';

class MockGearLocalDataSource extends Mock implements IGearLocalDataSource {}

class MockTripGearRemoteDataSource extends Mock implements ITripGearRemoteDataSource {}

class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeGearItem extends Fake implements GearItem {}

void main() {
  late GearSyncAdapter adapter;
  late MockGearLocalDataSource mockLocal;
  late MockTripGearRemoteDataSource mockRemote;
  late MockTripLocalDataSource mockTripLocal;
  late MockAppDatabase mockDb;

  setUpAll(() {
    registerFallbackValue(FakeGearItem());
  });

  setUp(() {
    mockLocal = MockGearLocalDataSource();
    mockRemote = MockTripGearRemoteDataSource();
    mockTripLocal = MockTripLocalDataSource();
    mockDb = MockAppDatabase();
    adapter = GearSyncAdapter(mockLocal, mockRemote, mockTripLocal, mockDb);
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

  group('GearSyncAdapter - pushOne', () {
    test('Given pendingCreate with same id, When pushOne, Then it adds remote gear and no migration', () async {
      when(() => mockRemote.addTripGear(any(), any())).thenAnswer((_) async => defaultItem);

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingCreate));

      expect(migration, isNull);
      verify(() => mockRemote.addTripGear('trip1', any())).called(1);
    });

    test('Given remote id differs in pendingCreate, When pushOne, Then it returns an IdMigration', () async {
      when(() => mockRemote.addTripGear(any(), any())).thenAnswer((_) async => defaultItem.copyWith(id: 'remote-gear-id'));

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingCreate));

      expect(migration?.tempId, 'gear1');
      expect(migration?.permanentId, 'remote-gear-id');
    });

    test('Given pendingUpdate, When pushOne, Then it updates remote gear', () async {
      when(() => mockRemote.updateTripGear(any(), any())).thenAnswer((_) async => defaultItem);

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingUpdate));

      expect(migration, isNull);
      verify(() => mockRemote.updateTripGear('trip1', any())).called(1);
    });

    test('Given pendingDelete, When pushOne, Then it deletes remote and local gear', () async {
      when(() => mockRemote.deleteTripGear(any(), any())).thenAnswer((_) async {});
      when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

      final migration = await adapter.pushOne(defaultItem.copyWith(syncStatus: SyncStatus.pendingDelete));

      expect(migration, isNull);
      verify(() => mockRemote.deleteTripGear('trip1', 'gear1')).called(1);
      verify(() => mockLocal.deleteById('gear1')).called(1);
    });
  });

  group('GearSyncAdapter - pullRemote', () {
    test('Given not exists in local, When pullRemote, Then it adds gear to local', () async {
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [scopeTrip]);
      when(() => mockRemote.getTripGear('trip1')).thenAnswer((_) async => [defaultItem]);
      when(() => mockLocal.getAll()).thenAnswer((_) async => []);
      when(() => mockLocal.getById(any())).thenAnswer((_) async => null);
      when(() => mockLocal.addItem(any())).thenAnswer((_) async => 1);

      final result = await adapter.pullRemote();

      expect(result.pulledCount, 1);
      expect(result.remoteWinsCount, 1);
      verify(() => mockLocal.addItem(any())).called(1);
    });

    test('Given remote deleted and local pending (wasEverSynced), When pullRemote, Then it deletes local gear', () async {
      final localItem = defaultItem.copyWith(syncStatus: SyncStatus.pendingUpdate);
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [scopeTrip]);
      when(() => mockRemote.getTripGear('trip1')).thenAnswer((_) async => []);
      when(() => mockLocal.getAll()).thenAnswer((_) async => [localItem]);
      when(() => mockLocal.deleteById(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.conflictCount, 1);
      verify(() => mockLocal.deleteById('gear1')).called(1);
    });

    test('Given local synced and remote updated, When pullRemote, Then it overwrites local', () async {
      final remoteItem = defaultItem.copyWith(name: 'Remote updated', updatedAt: DateTime(2026, 6, 6, 12, 1, 0));
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [scopeTrip]);
      when(() => mockRemote.getTripGear('trip1')).thenAnswer((_) async => [remoteItem]);
      when(() => mockLocal.getAll()).thenAnswer((_) async => [defaultItem]);
      when(() => mockLocal.getById('gear1')).thenAnswer((_) async => defaultItem);
      when(() => mockLocal.updateItem(any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.remoteWinsCount, 1);
      verify(() => mockLocal.updateItem(any())).called(1);
    });
  });
}
