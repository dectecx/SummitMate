import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:summitmate/services/sync_service.dart';
import 'package:summitmate/services/google_sheets_service.dart';
import 'package:summitmate/data/repositories/itinerary_repository.dart';
import 'package:summitmate/data/repositories/message_repository.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/repositories/settings_repository.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/services/log_service.dart';

// Mocks
class MockGoogleSheetsService extends Mock implements GoogleSheetsService {}

class MockItineraryRepository extends Mock implements ItineraryRepository {}

class MockMessageRepository extends Mock implements MessageRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSettings extends Mock implements Settings {}

void main() {
  late SyncService syncService;
  late MockGoogleSheetsService mockSheetsService;
  late MockItineraryRepository mockItineraryRepo;
  late MockMessageRepository mockMessageRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockSettings mockSettings;

  setUp(() {
    mockSheetsService = MockGoogleSheetsService();
    mockItineraryRepo = MockItineraryRepository();
    mockMessageRepo = MockMessageRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockSettings = MockSettings();

    // Default: Online mode
    when(() => mockSettings.isOfflineMode).thenReturn(false);
    when(() => mockSettingsRepo.getSettings()).thenReturn(mockSettings);

    // Default: No last sync time
    when(() => mockItineraryRepo.getLastSyncTime()).thenReturn(null);
    when(() => mockMessageRepo.getLastSyncTime()).thenReturn(null);

    // Default: Save sync time success
    when(() => mockItineraryRepo.saveLastSyncTime(any())).thenAnswer((_) async {});
    when(() => mockMessageRepo.saveLastSyncTime(any())).thenAnswer((_) async {});

    syncService = SyncService(
      sheetsService: mockSheetsService,
      itineraryRepo: mockItineraryRepo,
      messageRepo: mockMessageRepo,
      settingsRepo: mockSettingsRepo,
    );

    // Register fallback values
    registerFallbackValue(
      Message(uuid: 'fallback', user: 'user', category: 'Misc', content: 'content', timestamp: DateTime.now()),
    );
    // registerFallbackValue(Settings()); // HiveObject might be hard to instantiate directly without hive
  });

  group('SyncService Tests', () {
    test('syncAll should skip when offline', () async {
      // Arrange
      when(() => mockSettings.isOfflineMode).thenReturn(true);

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.success, isFalse);
      expect(result.errors, contains('目前為離線模式，無法同步'));
      verifyNever(() => mockSheetsService.fetchAll());
    });

    test('syncAll should coordinate full sync successfully', () async {
      // Arrange
      final cloudMessages = [
        Message(uuid: '1', user: 'Cloud', category: 'Misc', content: 'A', timestamp: DateTime.now()),
      ];
      final cloudItinerary = [
        ItineraryItem(day: 'D1', name: 'Start', estTime: '08:00', altitude: 2000, distance: 0, note: ''),
      ];

      when(
        () => mockSheetsService.fetchAll(),
      ).thenAnswer((_) async => FetchAllResult(success: true, itinerary: cloudItinerary, messages: cloudMessages));

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

    test('syncAll should NOT upload pending messages (cloud-only sync)', () async {
      // Arrange
      when(
        () => mockSheetsService.fetchAll(),
      ).thenAnswer((_) async => FetchAllResult(success: true, itinerary: [], messages: []));
      when(() => mockItineraryRepo.syncFromCloud(any())).thenAnswer((_) async {});
      when(() => mockMessageRepo.syncFromCloud(any())).thenAnswer((_) async {});

      // Act
      await syncService.syncAll();

      // Assert
      verifyNever(() => mockSheetsService.batchAddMessages(any()));
      verifyNever(() => mockMessageRepo.getPendingMessages(any()));
    });

    test('syncAll should handle fetch failure', () async {
      // Arrange
      when(
        () => mockSheetsService.fetchAll(),
      ).thenAnswer((_) async => FetchAllResult(success: false, errorMessage: 'Network Error'));

      // Act
      final result = await syncService.syncAll();

      // Assert
      expect(result.success, isFalse);
      expect(result.errors, contains('Network Error'));
      verifyNever(() => mockItineraryRepo.syncFromCloud(any()));
    });

    test('addMessageAndSync should save locally and upload to cloud', () async {
      // Arrange
      final newMsg = Message(uuid: 'new', user: 'Me', category: 'Plan', content: 'Hi', timestamp: DateTime.now());

      when(() => mockMessageRepo.addMessage(any())).thenAnswer((_) async {});
      when(() => mockSheetsService.addMessage(any())).thenAnswer((_) async => ApiResult(success: true));

      // Act
      final result = await syncService.addMessageAndSync(newMsg);

      // Assert
      expect(result.success, isTrue);
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
