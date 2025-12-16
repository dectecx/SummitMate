import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/services/sync_service.dart';
import 'package:summitmate/services/google_sheets_service.dart';
import 'package:summitmate/data/repositories/itinerary_repository.dart';
import 'package:summitmate/data/repositories/message_repository.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/itinerary_item.dart';

// Mocks
class MockGoogleSheetsService extends Mock implements GoogleSheetsService {}
class MockItineraryRepository extends Mock implements ItineraryRepository {}
class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late SyncService syncService;
  late MockGoogleSheetsService mockSheetsService;
  late MockItineraryRepository mockItineraryRepo;
  late MockMessageRepository mockMessageRepo;

  setUp(() {
    mockSheetsService = MockGoogleSheetsService();
    mockItineraryRepo = MockItineraryRepository();
    mockMessageRepo = MockMessageRepository();

    syncService = SyncService(
      sheetsService: mockSheetsService,
      itineraryRepo: mockItineraryRepo,
      messageRepo: mockMessageRepo,
    );

    // Register fallback values
    registerFallbackValue(Message(
      uuid: 'fallback',
      user: 'user',
      category: 'Misc',
      content: 'content',
      timestamp: DateTime.now(),
    ));
  });

  group('SyncService Tests', () {
    test('syncAll should coordinate full sync successfully', () async {
      // Arrange
      final cloudMessages = [
        Message(uuid: '1', user: 'Cloud', category: 'Misc', content: 'A', timestamp: DateTime.now())
      ];
      final cloudItinerary = [
         ItineraryItem(day: 'D1', name: 'Start', estTime: '08:00', altitude: 2000, distance: 0, note: '')
      ];
      
      when(() => mockSheetsService.fetchAll()).thenAnswer((_) async => FetchAllResult(
        success: true,
        itinerary: cloudItinerary,
        messages: cloudMessages,
      ));
      
      when(() => mockItineraryRepo.syncFromCloud(any())).thenAnswer((_) async {});
      when(() => mockMessageRepo.getPendingMessages(any())).thenReturn([]);
      when(() => mockMessageRepo.syncFromCloud(any())).thenAnswer((_) async {});

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.success, isTrue);
      verify(() => mockSheetsService.fetchAll()).called(1);
      verify(() => mockItineraryRepo.syncFromCloud(cloudItinerary)).called(1);
      verify(() => mockMessageRepo.syncFromCloud(cloudMessages)).called(1);
    });

    test('syncAll should upload pending messages', () async {
      // Arrange
      final pendingMsg = Message(uuid: 'pending', user: 'Local', category: 'Misc', content: 'B', timestamp: DateTime.now());
      
      when(() => mockSheetsService.fetchAll()).thenAnswer((_) async => FetchAllResult(
        success: true,
        itinerary: [],
        messages: [],
      ));
      when(() => mockItineraryRepo.syncFromCloud(any())).thenAnswer((_) async {});
      
      // Simulate one pending message
      when(() => mockMessageRepo.getPendingMessages(any())).thenReturn([pendingMsg]);
      when(() => mockSheetsService.addMessage(any())).thenAnswer((_) async => ApiResult(success: true));
      when(() => mockMessageRepo.syncFromCloud(any())).thenAnswer((_) async {});

      // Act
      await syncService.syncAll();

      // Assert
      verify(() => mockSheetsService.addMessage(pendingMsg)).called(1);
    });

    test('syncAll should handle fetch failure', () async {
      // Arrange
      when(() => mockSheetsService.fetchAll()).thenAnswer((_) async => FetchAllResult(
        success: false,
        errorMessage: 'Network Error',
      ));

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.success, isFalse);
      expect(result.errors, contains('Network Error'));
      verifyNever(() => mockItineraryRepo.syncFromCloud(any()));
    });

    test('addMessageAndSync should save locally and then upload', () async {
      // Arrange
      final newMsg = Message(uuid: 'new', user: 'Me', category: 'Plan', content: 'Hi', timestamp: DateTime.now());
      
      when(() => mockMessageRepo.addMessage(any())).thenAnswer((_) async {});
      when(() => mockSheetsService.addMessage(any())).thenAnswer((_) async => ApiResult(success: true));

      // Act
      final result = await syncService.addMessageAndSync(newMsg);

      // Assert
      expect(result.success, isTrue);
      // Verify order: local first, then cloud
      verify(() => mockMessageRepo.addMessage(newMsg)).called(1);
      verify(() => mockSheetsService.addMessage(newMsg)).called(1);
    });

    test('deleteMessageAndSync should delete locally and then from cloud', () async {
      // Arrange
      const uuid = 'delete-me';
      
      when(() => mockMessageRepo.deleteByUuid(any())).thenAnswer((_) async {});
      when(() => mockSheetsService.deleteMessage(any())).thenAnswer((_) async => ApiResult(success: true));

      // Act
      final result = await syncService.deleteMessageAndSync(uuid);

      // Assert
      expect(result.success, isTrue);
      verify(() => mockMessageRepo.deleteByUuid(uuid)).called(1);
      verify(() => mockSheetsService.deleteMessage(uuid)).called(1);
    });
  });
}
