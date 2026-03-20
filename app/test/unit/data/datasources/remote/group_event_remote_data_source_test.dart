import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/group_event_remote_data_source.dart';
import 'package:summitmate/data/models/group_event.dart';
import 'package:summitmate/data/models/enums/group_event_status.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  late GroupEventRemoteDataSource dataSource;
  late MockNetworkAwareClient mockApiClient;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    dataSource = GroupEventRemoteDataSource(apiClient: mockApiClient);
  });

  group('GroupEventRemoteDataSource.getEvents', () {
    test('returns list of events on success', () async {
      final responseData = [
        {
          'id': 'event-1',
          'title': 'Hiking Trip',
          'description': 'Let\'s go!',
          'creator_id': 'user-1',
          'status': 'open',
          'start_date': '2024-01-01T00:00:00Z',
          'created_at': '2024-01-01T00:00:00Z',
          'created_by': 'user-1',
          'updated_at': '2024-01-01T00:00:00Z',
          'updated_by': 'user-1',
        },
      ];

      when(() => mockApiClient.get('/group-events', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getEvents(userId: 'user-123');

      expect(result.length, 1);
      expect(result[0].title, 'Hiking Trip');
    });
  });

  group('GroupEventRemoteDataSource CRUD', () {
    test('createEvent returns ID', () async {
      final event = GroupEvent(
        id: 'e1',
        creatorId: 'u1',
        title: 'New Event',
        startDate: DateTime(2024, 1, 1),
        status: GroupEventStatus.open,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'u1',
        updatedAt: DateTime(2024, 1, 1),
        updatedBy: 'u1',
      );

      when(() => mockApiClient.post('/group-events', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'id': 'evt-999'},
          statusCode: 201,
        ),
      );

      final result = await dataSource.createEvent(event);

      expect(result, 'evt-999');
    });

    test('deleteEvent calls delete', () async {
      when(
        () => mockApiClient.delete('/group-events/evt-1'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 204));

      await dataSource.deleteEvent(eventId: 'evt-1', userId: 'u1');

      verify(() => mockApiClient.delete('/group-events/evt-1')).called(1);
    });
  });

  group('Application and Comments', () {
    test('applyEvent returns application ID', () async {
      when(() => mockApiClient.post('/group-events/evt-1/apply', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'id': 'app-123'},
          statusCode: 201,
        ),
      );

      final result = await dataSource.applyEvent(eventId: 'evt-1', userId: 'u1', message: 'Pick me!');

      expect(result, 'app-123');
    });

    test('addComment returns comment object', () async {
      final commentJson = {
        'id': 'c1',
        'event_id': 'e1',
        'user_id': 'u1',
        'content': 'Nice!',
        'user_name': 'Test User',
        'user_avatar': '🐻',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      when(() => mockApiClient.post('/group-events/e1/comments', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: commentJson,
          statusCode: 201,
        ),
      );

      final result = await dataSource.addComment(eventId: 'e1', userId: 'u1', content: 'Nice!');

      expect(result.content, 'Nice!');
      expect(result.id, 'c1');
    });
  });
}
