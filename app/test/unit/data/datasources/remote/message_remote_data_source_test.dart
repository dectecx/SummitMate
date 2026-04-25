import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/message_api_models.dart';
import 'package:summitmate/data/api/services/message_api_service.dart';
import 'package:summitmate/data/datasources/remote/message_remote_data_source.dart';
import 'package:summitmate/core/error/result.dart';

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
        'pagination': {
          'next_cursor': null,
          'has_more': false,
          'page': 1,
          'limit': 20,
          'total': 1,
        },
      });
      when(() => mockApiService.listTripMessages(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => paginationResponse);

      final result = await dataSource.getMessages('trip-1');

      expect(result, isA<Success>());
      final paginated = (result as Success).value;
      expect(paginated.items.length, 1);
      expect(paginated.items[0].id, 'msg-1');
      expect(paginated.items[0].content, 'Hello world');
    });

    test('returns failure on error', () async {
      when(() => mockApiService.listTripMessages(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Error'));

      final result = await dataSource.getMessages('fail');

      expect(result, isA<Failure>());
    });
  });

  group('MessageRemoteDataSource operations', () {
    test('addMessage calls api correctly', () async {
      when(() => mockApiService.addMessage(any(), any())).thenAnswer((_) async => testResponse);

      final result = await dataSource.addMessage(tripId: 'trip-1', content: 'Hello world');

      expect(result, isA<Success>());
      verify(() => mockApiService.addMessage('trip-1', any())).called(1);
    });

    test('deleteMessage calls api correctly', () async {
      when(() => mockApiService.deleteMessage('trip-1', 'msg-1')).thenAnswer((_) async {});

      final result = await dataSource.deleteMessage('trip-1', 'msg-1');

      expect(result, isA<Success>());
      verify(() => mockApiService.deleteMessage('trip-1', 'msg-1')).called(1);
    });
  });
}
