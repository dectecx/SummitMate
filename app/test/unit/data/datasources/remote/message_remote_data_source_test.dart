import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/message_api_models.dart';
import 'package:summitmate/data/api/services/message_api_service.dart';
import 'package:summitmate/data/datasources/remote/message_remote_data_source.dart';
import 'package:summitmate/data/models/message.dart';

class MockMessageApiService extends Mock implements MessageApiService {}

class FakeMessageCreateRequest extends Fake implements MessageCreateRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMessageCreateRequest());
  });

  late MessageRemoteDataSource dataSource;
  late MockMessageApiService mockApiService;

  setUp(() {
    mockApiService = MockMessageApiService();
    dataSource = MessageRemoteDataSource(mockApiService);
  });

  final testResponse = MessageResponse.fromJson({
    'id': 'msg-1',
    'trip_id': 'trip-1',
    'user_id': 'user-1',
    'display_name': 'Test User',
    'avatar': '🐻',
    'category': 'general',
    'content': 'Hello world',
    'timestamp': '2024-01-01T00:00:00Z',
    'created_at': '2024-01-01T00:00:00Z',
  });

  group('MessageRemoteDataSource.getMessages', () {
    test('returns list of messages on success', () async {
      final paginationResponse = MessagePaginationResponse.fromJson({
        'items': [
          {
            'id': 'msg-1',
            'trip_id': 'trip-1',
            'user_id': 'user-1',
            'display_name': 'Test User',
            'avatar': '🐻',
            'category': 'general',
            'content': 'Hello world',
            'timestamp': '2024-01-01T00:00:00Z',
            'created_at': '2024-01-01T00:00:00Z',
          }
        ],
        'pagination': {'next_cursor': null, 'has_more': false},
      });
      when(() => mockApiService.listTripMessages('trip-1')).thenAnswer((_) async => paginationResponse);

      final result = await dataSource.getMessages('trip-1');

      expect(result.items.length, 1);
      expect(result.items[0].id, 'msg-1');
      expect(result.items[0].content, 'Hello world');
    });

    test('throws exception on error', () async {
      when(() => mockApiService.listTripMessages('fail')).thenThrow(Exception('Error'));

      expect(() => dataSource.getMessages('fail'), throwsException);
    });
  });

  group('MessageRemoteDataSource operations', () {
    test('addMessage calls api correctly', () async {
      when(() => mockApiService.addMessage('trip-1', any())).thenAnswer((_) async => testResponse);

      final message = Message.fromJson({
        'id': 'msg-1',
        'trip_id': 'trip-1',
        'user_id': 'user-1',
        'content': 'Hello world',
        'timestamp': '2024-01-01T00:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
        'created_by': 'user-1',
        'updated_at': '2024-01-01T00:00:00Z',
        'updated_by': 'user-1',
      });

      await dataSource.addMessage(message);

      verify(() => mockApiService.addMessage('trip-1', any())).called(1);
    });

    test('deleteMessage calls api correctly', () async {
      when(() => mockApiService.deleteMessage('trip-1', 'msg-1')).thenAnswer((_) async {});

      await dataSource.deleteMessage('trip-1', 'msg-1');

      verify(() => mockApiService.deleteMessage('trip-1', 'msg-1')).called(1);
    });
  });
}
