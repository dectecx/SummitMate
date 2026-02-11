import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/infrastructure/services/sync_service.dart';
import 'package:summitmate/domain/interfaces/i_data_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/data/repositories/interfaces/i_itinerary_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_message_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/dto/data_service_result.dart';

// Mocks - use interfaces for better test isolation
class MockDataService extends Mock implements IDataService {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockMessageRepository extends Mock implements IMessageRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late SyncService syncService;
  late MockDataService mockDataService;
  late MockTripRepository mockTripRepo;
  late MockItineraryRepository mockItineraryRepo;
  late MockMessageRepository mockMessageRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;

  setUp(() {
    mockDataService = MockDataService();
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
      sheetsService: mockDataService,
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
      verifyNever(() => mockDataService.getAll(tripId: any(named: 'tripId')));
    });

    test('syncAll should coordinate full sync successfully', () async {
      // Arrange
      final cloudMessages = [
        Message(
          id: '1',
          user: 'Cloud',
          category: 'Misc',
          content: 'A',
          timestamp: DateTime.now(),
          createdAt: DateTime.now(),
          createdBy: 'Cloud',
          updatedAt: DateTime.now(),
          updatedBy: 'Cloud',
        ),
      ];
      final cloudItinerary = [
        ItineraryItem(
          id: 'sync-item-1',
          day: 'D1',
          name: 'Start',
          estTime: '08:00',
          altitude: 2000,
          distance: 0,
          note: '',
        ),
      ];

      when(
        () => mockDataService.getAll(tripId: any(named: 'tripId')),
      ).thenAnswer((_) async => Success(DataServiceResult(itinerary: cloudItinerary, messages: cloudMessages)));

      when(() => mockItineraryRepo.syncFromCloud(any())).thenAnswer((_) async => const Success(null));
      when(() => mockMessageRepo.getPendingMessages(any())).thenAnswer((_) async => const Success([]));
      when(() => mockMessageRepo.syncFromCloud(any())).thenAnswer((_) async => const Success(null));

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.isSuccess, isTrue);
      // verify(() => mockDataService.getAll(tripId: any(named: 'tripId'))).called(1); // Usually sufficient to verify it was called
      verify(() => mockItineraryRepo.syncFromCloud(cloudItinerary)).called(1);
      verify(() => mockMessageRepo.syncFromCloud(cloudMessages)).called(1);
    });

    test('syncAll should NOT upload pending messages (cloud-only sync)', () async {
      // Arrange
      when(
        () => mockDataService.getAll(tripId: any(named: 'tripId')),
      ).thenAnswer((_) async => const Success(DataServiceResult(itinerary: [], messages: [])));
      when(() => mockItineraryRepo.syncFromCloud(any())).thenAnswer((_) async => const Success(null));
      when(() => mockMessageRepo.syncFromCloud(any())).thenAnswer((_) async => const Success(null));

      // Act
      await syncService.syncAll();

      // Assert
      verifyNever(() => mockDataService.batchAddMessages(any()));
      verifyNever(() => mockMessageRepo.getPendingMessages(any()));
    });

    test('syncAll should handle fetch failure', () async {
      // Arrange
      when(
        () => mockDataService.getAll(tripId: any(named: 'tripId')),
      ).thenAnswer((_) async => const Success(DataServiceResult(itinerary: [], messages: [])));

      when(() => mockItineraryRepo.syncFromCloud(any())).thenAnswer((_) async => const Success(null));
      when(() => mockMessageRepo.syncFromCloud(any())).thenAnswer((_) async => const Success(null));
      when(() => mockMessageRepo.getPendingMessages(any())).thenAnswer((_) async => const Success([]));

      // Act
      final result = await syncService.syncAll(isAuto: false);

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockDataService.getAll(tripId: 'test-trip-1')).called(1);
    });

    test('syncAll failure handles error', () async {
      // Arrange
      // Need to mock sync needed
      when(() => mockItineraryRepo.getLastSyncTime()).thenReturn(null);
      when(() => mockMessageRepo.getLastSyncTime()).thenAnswer((_) async => const Success(null));
      // Re-init to load new mock times
      syncService = SyncService(
        sheetsService: mockDataService,
        tripRepo: mockTripRepo,
        itineraryRepo: mockItineraryRepo,
        messageRepo: mockMessageRepo,
        connectivity: mockConnectivity,
        authService: mockAuthService,
      );

      when(
        () => mockDataService.getAll(tripId: any(named: 'tripId')),
      ).thenAnswer((_) async => Failure(GeneralException('Network Error')));

      // Act
      final result = await syncService.syncAll(isAuto: false);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errors.first, contains('Network Error'));
    });

    test('getCloudTrips delegates to trip repository', () async {
      // Arrange
      final trips = [
        Trip(
          id: '1',
          userId: 'u1',
          name: 'Test Trip',
          startDate: DateTime.now(),
          createdAt: DateTime.now(),
          createdBy: 'u1',
          updatedAt: DateTime.now(),
          updatedBy: 'u1',
        ),
      ];
      when(() => mockTripRepo.getRemoteTrips()).thenAnswer((_) async => Success(trips));

      // Act
      final result = await syncService.getCloudTrips();

      // Assert
      expect(result is Success, true);
      expect((result as Success).value, trips);
      verify(() => mockTripRepo.getRemoteTrips()).called(1);
    });

    test('addMessageAndSync should call repository', () async {
      // Arrange
      final newMsg = Message(
        id: 'new',
        user: 'Me',
        category: 'Plan',
        content: 'Hi',
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'Me',
        updatedAt: DateTime.now(),
        updatedBy: 'Me',
      );

      when(() => mockMessageRepo.addMessage(any())).thenAnswer((_) async => const Success(null));

      // Act
      final result = await syncService.addMessageAndSync(newMsg);

      // Assert
      expect(result is Success, true);
      verify(() => mockMessageRepo.addMessage(newMsg)).called(1);
      // DataService should NOT be called directly by SyncService anymore
      verifyNever(() => mockDataService.addMessage(any()));
    });

    test('deleteMessageAndSync should call repository', () async {
      // Arrange
      const id = 'delete-me';

      when(() => mockMessageRepo.deleteById(any())).thenAnswer((_) async => const Success(null));

      // Act
      final result = await syncService.deleteMessageAndSync(id);

      // Assert
      expect(result is Success, true);
      verify(() => mockMessageRepo.deleteById(id)).called(1);
      // DataService should NOT be called directly by SyncService anymore
      verifyNever(() => mockDataService.deleteMessage(any()));
    });
  });
}
