import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/infrastructure/services/sync_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/data/repositories/interfaces/i_itinerary_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_message_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/core/error/result.dart';

// Mocks - use interfaces for better test isolation

class MockTripRepository extends Mock implements ITripRepository {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockMessageRepository extends Mock implements IMessageRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late SyncService syncService;
  late MockTripRepository mockTripRepo;
  late MockItineraryRepository mockItineraryRepo;
  late MockMessageRepository mockMessageRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockItineraryRepo = MockItineraryRepository();
    mockMessageRepo = MockMessageRepository();
    mockConnectivity = MockConnectivityService();
    mockAuthService = MockAuthService();

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

    // Default: No last sync time
    when(() => mockItineraryRepo.getLastSyncTime()).thenReturn(null);
    when(() => mockMessageRepo.getLastSyncTime()).thenAnswer((_) async => const Success(null));

    // Default: Save sync time success
    when(() => mockItineraryRepo.saveLastSyncTime(any())).thenAnswer((_) async => const Success(null));
    when(() => mockMessageRepo.saveLastSyncTime(any())).thenAnswer((_) async => const Success(null));

    syncService = SyncService(
      tripRepo: mockTripRepo,
      itineraryRepo: mockItineraryRepo,
      messageRepo: mockMessageRepo,
      connectivity: mockConnectivity,
      authService: mockAuthService,
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
    // registerFallbackValue(Settings()); // HiveObject might be hard to instantiate directly without hive
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
      when(() => mockMessageRepo.sync(any())).thenAnswer((_) async => const Success(null));

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.isSuccess, isTrue);
      // Wait for async operations
      verify(() => mockItineraryRepo.sync('test-trip-1')).called(1);
      verify(() => mockMessageRepo.sync('test-trip-1')).called(1);
    });

    test('syncAll failure handles error', () async {
      // Arrange
      when(() => mockItineraryRepo.getLastSyncTime()).thenReturn(null);
      when(() => mockMessageRepo.getLastSyncTime()).thenAnswer((_) async => const Success(null));
      // Re-init to load new mock times
      syncService = SyncService(
        tripRepo: mockTripRepo,
        itineraryRepo: mockItineraryRepo,
        messageRepo: mockMessageRepo,
        connectivity: mockConnectivity,
        authService: mockAuthService,
      );

      when(() => mockItineraryRepo.sync(any())).thenThrow(Exception('Network Error'));
      when(() => mockMessageRepo.sync(any())).thenAnswer((_) async => const Success(null));

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
      final paginated = PaginatedList(items: [trip], nextCursor: null, hasMore: false);
      when(() => mockTripRepo.getRemoteTrips()).thenAnswer((_) async => Success(paginated));

      // Act
      final result = await syncService.getCloudTrips();

      // Assert
      expect(result is Success, true);
      final value = (result as Success<PaginatedList<Trip>, Exception>).value;
      expect(value.items, [trip]);
      verify(() => mockTripRepo.getRemoteTrips()).called(1);
    });
  });
}
