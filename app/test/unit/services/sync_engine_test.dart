import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/adapters/trip_sync_adapter.dart';
import 'package:summitmate/infrastructure/services/adapters/itinerary_sync_adapter.dart';
import 'package:summitmate/infrastructure/services/adapters/gear_sync_adapter.dart';
import 'package:summitmate/infrastructure/services/sync_engine.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockMessageRepository extends Mock implements IMessageRepository {}

class MockGroupEventRepository extends Mock implements IGroupEventRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockItineraryLocalDataSource extends Mock implements IItineraryLocalDataSource {}

class MockGearLocalDataSource extends Mock implements IGearLocalDataSource {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

class MockTripSyncAdapter extends Mock implements TripSyncAdapter {}

class MockItinerarySyncAdapter extends Mock implements ItinerarySyncAdapter {}

class MockGearSyncAdapter extends Mock implements GearSyncAdapter {}

class MockSettings extends Mock implements Settings {}

void main() {
  late SyncEngine engine;
  late MockTripRepository mockTripRepo;
  late MockItineraryRepository mockItineraryRepo;
  late MockGearRepository mockGearRepo;
  late MockMessageRepository mockMessageRepo;
  late MockGroupEventRepository mockEventRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;
  late MockAppDatabase mockDb;
  late MockItineraryLocalDataSource mockItineraryLocal;
  late MockGearLocalDataSource mockGearLocal;
  late MockTripRemoteDataSource mockTripRemote;
  late MockTripSyncAdapter mockTripSync;
  late MockItinerarySyncAdapter mockItinerarySync;
  late MockGearSyncAdapter mockGearSync;
  late MockSettings mockSettings;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockItineraryRepo = MockItineraryRepository();
    mockGearRepo = MockGearRepository();
    mockMessageRepo = MockMessageRepository();
    mockEventRepo = MockGroupEventRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockConnectivity = MockConnectivityService();
    mockAuthService = MockAuthService();
    mockDb = MockAppDatabase();
    mockItineraryLocal = MockItineraryLocalDataSource();
    mockGearLocal = MockGearLocalDataSource();
    mockTripRemote = MockTripRemoteDataSource();
    mockTripSync = MockTripSyncAdapter();
    mockItinerarySync = MockItinerarySyncAdapter();
    mockGearSync = MockGearSyncAdapter();
    mockSettings = MockSettings();

    // Stub watchSettings to allow construction
    when(() => mockSettingsRepo.watchSettings()).thenAnswer((_) => const Stream.empty());
    // Stub getSettings
    when(() => mockSettings.autoSyncIntervalMinutes).thenReturn(15);
    when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => mockSettings);

    engine = SyncEngine(
      tripRepo: mockTripRepo,
      itineraryRepo: mockItineraryRepo,
      gearRepo: mockGearRepo,
      messageRepo: mockMessageRepo,
      eventRepo: mockEventRepo,
      settingsRepo: mockSettingsRepo,
      connectivity: mockConnectivity,
      authService: mockAuthService,
      db: mockDb,
      itineraryLocalDataSource: mockItineraryLocal,
      gearLocalDataSource: mockGearLocal,
      tripRemoteDataSource: mockTripRemote,
      tripSyncAdapter: mockTripSync,
      itinerarySyncAdapter: mockItinerarySync,
      gearSyncAdapter: mockGearSync,
    );
  });

  group('SyncEngine - runSyncCycle', () {
    test('Given connectivity is offline, When calling runSyncCycle, Then it should return failure', () async {
      when(() => mockConnectivity.isOffline).thenReturn(true);

      final result = await engine.runSyncCycle();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('離線模式'));
    });

    test(
      'Given runSyncCycle, When triggered, Then it should call adapters and repos during normal sync cycle',
      () async {
        when(() => mockConnectivity.isOffline).thenReturn(false);
        when(() => mockAuthService.currentUserId).thenReturn('user1');

        // Stub Push
        when(() => mockTripRepo.getAllTrips(any())).thenAnswer((_) async => const Success([]));
        when(() => mockItineraryLocal.getAll()).thenAnswer((_) async => []);
        when(() => mockGearLocal.getAll()).thenAnswer((_) async => []);

        // Stub Pull
        when(() => mockTripSync.pullAndMerge(any())).thenAnswer(
          (_) async =>
              const Success(SyncMergeResult(pulledCount: 0, conflictCount: 0, localWinsCount: 0, remoteWinsCount: 0)),
        );

        // Stub T2 syncs
        when(() => mockTripRepo.getActiveTrip(any())).thenAnswer((_) async => const Success(null));
        when(() => mockEventRepo.syncEvents()).thenAnswer((_) async => const Success([]));

        // Stub settings update
        when(() => mockSettingsRepo.updateLastSyncTime(any())).thenAnswer((_) async {});

        final result = await engine.runSyncCycle();

        expect(result.isSuccess, isTrue);
        verify(() => mockTripSync.pullAndMerge('user1')).called(1);
        verify(() => mockSettingsRepo.updateLastSyncTime(any())).called(1);
      },
    );
  });
}
