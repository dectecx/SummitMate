import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_message_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/presentation/providers/message_provider.dart';
import 'package:summitmate/services/google_sheets_service.dart';
import 'package:summitmate/services/sync_service.dart';

// Mocks
class MockMessageRepository extends Mock implements IMessageRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockTripRepository extends Mock implements ITripRepository {}

void main() {
  late MessageProvider provider;
  late MockMessageRepository mockRepository;
  late MockSyncService mockSyncService;
  late MockTripRepository mockTripRepository;

  setUp(() async {
    mockRepository = MockMessageRepository();
    mockSyncService = MockSyncService();
    mockTripRepository = MockTripRepository();

    // Reset GetIt
    await GetIt.I.reset();
    GetIt.I.registerSingleton<IMessageRepository>(mockRepository);
    GetIt.I.registerSingleton<SyncService>(mockSyncService);
    GetIt.I.registerSingleton<ITripRepository>(mockTripRepository);

    // Default mock behaviors
    when(() => mockRepository.getAllMessages()).thenReturn([]);
    when(
      () => mockTripRepository.getActiveTrip(),
    ).thenReturn(Trip(id: 'test-trip-1', name: 'Test Trip', startDate: DateTime.now()));
    registerFallbackValue(
      Message(uuid: 'fallback', user: 'user', category: 'Chat', content: 'content', timestamp: DateTime.now()),
    );
  });

  group('MessageProvider Logic Tests', () {
    test('should load messages on initialization', () {
      // Arrange
      final messages = [Message(uuid: '1', user: 'A', category: 'Gear', content: 'Msg 1', timestamp: DateTime.now())];
      when(() => mockRepository.getAllMessages()).thenReturn(messages);

      // Act
      provider = MessageProvider();

      // Assert
      expect(provider.allMessages, equals(messages));
      verify(() => mockRepository.getAllMessages()).called(1);
    });

    test('get currentCategoryMessages should filter by category and exclude replies', () {
      // Arrange
      final now = DateTime.now();
      final messages = [
        Message(uuid: '1', user: 'A', category: 'Gear', content: 'Main', timestamp: now),
        Message(uuid: '2', user: 'A', category: 'Gear', content: 'Reply', parentId: '1', timestamp: now),
        Message(uuid: '3', user: 'A', category: 'Chat', content: 'Chat', timestamp: now),
      ];
      when(() => mockRepository.getAllMessages()).thenReturn(messages);

      provider = MessageProvider();
      provider.selectCategory('Gear');

      // Act
      final result = provider.currentCategoryMessages;

      // Assert
      expect(result.length, 1);
      expect(result.first.uuid, '1'); // Only main Gear message
    });

    test('getReplies should return children of specific parent', () {
      // Arrange
      final now = DateTime.now();
      final messages = [
        Message(uuid: '1', user: 'A', category: 'Gear', content: 'Main', timestamp: now),
        Message(
          uuid: '2',
          user: 'A',
          category: 'Gear',
          content: 'Reply 1',
          parentId: '1',
          timestamp: now.add(Duration(seconds: 1)),
        ),
        Message(
          uuid: '3',
          user: 'A',
          category: 'Gear',
          content: 'Reply 2',
          parentId: '1',
          timestamp: now.add(Duration(seconds: 2)),
        ),
      ];
      when(() => mockRepository.getAllMessages()).thenReturn(messages);

      provider = MessageProvider();

      // Act
      final result = provider.getReplies('1');

      // Assert
      expect(result.length, 2);
      expect(result.first.uuid, '2');
      expect(result.last.uuid, '3');
    });

    test('addMessage should call syncService and reload', () async {
      // Arrange
      when(() => mockRepository.getAllMessages()).thenReturn([]);
      when(() => mockSyncService.addMessageAndSync(any())).thenAnswer((_) async => ApiResult(isSuccess: true));

      provider = MessageProvider();

      // Act
      await provider.addMessage(user: 'TestUser', avatar: '🐻', content: 'Hello');

      // Assert
      verify(() => mockSyncService.addMessageAndSync(any())).called(1);
      // getAllMessages called twice: init, and after add
      verify(() => mockRepository.getAllMessages()).called(2);
    });

    test('deleteMessage should call syncService and reload', () async {
      // Arrange
      when(() => mockRepository.getAllMessages()).thenReturn([]);
      when(() => mockSyncService.deleteMessageAndSync(any())).thenAnswer((_) async => ApiResult(isSuccess: true));

      provider = MessageProvider();

      // Act
      await provider.deleteMessage('some-uuid');

      // Assert
      verify(() => mockSyncService.deleteMessageAndSync('some-uuid')).called(1);
      verify(() => mockRepository.getAllMessages()).called(2);
    });
  });
}
