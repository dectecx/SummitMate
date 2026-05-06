import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/infrastructure/services/sync_service.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';

// Mocks - use interfaces for better test isolation

class MockTripRepository extends Mock implements ITripRepository {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockMessageRepository extends Mock implements IMessageRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockGroupEventRepository extends Mock implements IGroupEventRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late SyncService syncService;
  late MockTripRepository mockTripRepo;
  late MockItineraryRepository mockItineraryRepo;
  late MockMessageRepository mockMessageRepo;
  late MockGearRepository mockGearRepo;
  late MockGroupEventRepository mockEventRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;
  late MockAppDatabase mockDb;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockItineraryRepo = MockItineraryRepository();
    mockMessageRepo = MockMessageRepository();
    mockGearRepo = MockGearRepository();
    mockEventRepo = MockGroupEventRepository();
    mockConnectivity = MockConnectivityService();
    mockAuthService = MockAuthService();
    mockDb = MockAppDatabase();

    when(() => mockAuthService.currentUserId).thenReturn('u1');

    // Default: Online mode
    when(() => mockConnectivity.isOffline).thenReturn(false);

    // Default: Active trip
    when(() => mockTripRepo.getActiveTrip(any())).thenAnswer(
      (_) async => Success(
        Trip(
          id: 'test-trip-1',
          userId: 'u1',
          name: 'Test Trip',
          startDate: DateTime.now(),
          isActive: true,
          createdAt: DateTime.now(),
          createdBy: 'u1',
          updatedAt: DateTime.now(),
          updatedBy: 'u1',
        ),
      ),
    );

    // Default: Itinerary sync behavior
    when(() => mockItineraryRepo.sync(any())).thenAnswer((_) async => const Success(null));
    when(() => mockGearRepo.sync(any())).thenAnswer((_) async => const Success(null));
    when(() => mockEventRepo.syncEvents(category: any(named: 'category'))).thenAnswer((_) async => const Success([]));

    // Default: Message sync behavior
    when(
      () => mockMessageRepo.getRemoteMessages(any()),
    ).thenAnswer((_) async => Success(PaginatedList<Message>(items: [], page: 1, total: 0, hasMore: false)));

    syncService = SyncService(
      tripRepo: mockTripRepo,
      itineraryRepo: mockItineraryRepo,
      messageRepo: mockMessageRepo,
      gearRepo: mockGearRepo,
      eventRepo: mockEventRepo,
      connectivity: mockConnectivity,
      authService: mockAuthService,
      db: mockDb,
    );

    // Register fallback values
    registerFallbackValue(
      Message(
        id: 'fallback',
        user: 'user',
        category: 'Misc',
        content: 'content',
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'user',
        updatedAt: DateTime.now(),
        updatedBy: 'user',
      ),
    );
  });

  group('SyncService Tests', () {
    test('syncAll should skip when offline', () async {
      // Arrange
      when(() => mockConnectivity.isOffline).thenReturn(true);

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errors, contains('目前為離線模式，無法同步'));
    });

    test('syncAll should coordinate full sync successfully', () async {
      // Arrange
      when(() => mockItineraryRepo.sync(any())).thenAnswer((_) async => const Success(null));
      when(
        () => mockMessageRepo.getRemoteMessages(any()),
      ).thenAnswer((_) async => Success(PaginatedList<Message>(items: [], page: 1, total: 0, hasMore: false)));

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockItineraryRepo.sync('test-trip-1')).called(1);
      verify(() => mockMessageRepo.getRemoteMessages('test-trip-1')).called(1);
      verify(() => mockGearRepo.sync('test-trip-1')).called(1);
      verify(() => mockEventRepo.syncEvents()).called(1);
    });

    test('syncAll failure handles error', () async {
      // Arrange
      when(() => mockItineraryRepo.sync(any())).thenThrow(Exception('Network Error'));
      when(
        () => mockMessageRepo.getRemoteMessages(any()),
      ).thenAnswer((_) async => Success(PaginatedList<Message>(items: [], page: 1, total: 0, hasMore: false)));

      // Act
      final result = await syncService.syncAll(isAuto: false);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errors.first, contains('Network Error'));
    });

    test('getCloudTrips delegates to trip repository', () async {
      // Arrange
      final trip = Trip(
        id: '1',
        userId: 'u1',
        name: 'Test Trip',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'u1',
        updatedAt: DateTime.now(),
        updatedBy: 'u1',
      );
      final paginated = PaginatedList<Trip>(items: [trip], page: 1, total: 1, hasMore: false);
      when(
        () => mockTripRepo.getRemoteTrips(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => Success(paginated));

      // Act
      final result = await syncService.getCloudTrips();

      // Assert
      expect(result is Success, true);
      final value = (result as Success<PaginatedList<Trip>, Exception>).value;
      expect(value.items, [trip]);
      verify(
        () => mockTripRepo.getRemoteTrips(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).called(1);
    });
  });
}
