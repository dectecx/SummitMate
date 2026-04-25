import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/group_event_api_models.dart';
import 'package:summitmate/data/api/services/group_event_api_service.dart';
import 'package:summitmate/data/datasources/remote/group_event_remote_data_source.dart';
import 'package:summitmate/data/models/group_event.dart';
import 'package:summitmate/data/models/enums/group_event_status.dart';

class MockGroupEventApiService extends Mock implements GroupEventApiService {}

class FakeGroupEventCreateRequest extends Fake implements GroupEventCreateRequest {}

class FakeGroupEventCommentRequest extends Fake implements GroupEventCommentRequest {}

class FakeGroupEventApplyRequest extends Fake implements GroupEventApplyRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGroupEventCreateRequest());
    registerFallbackValue(FakeGroupEventCommentRequest());
    registerFallbackValue(FakeGroupEventApplyRequest());
  });

  late GroupEventRemoteDataSource dataSource;
  late MockGroupEventApiService mockApiService;

  setUp(() {
    mockApiService = MockGroupEventApiService();
    dataSource = GroupEventRemoteDataSource(mockApiService);
  });

  final testEventResponse = GroupEventResponse.fromJson({
    'id': 'evt-999',
    'title': 'Hiking Trip',
    'creator_id': 'u1',
    'creator_name': 'User 1',
    'creator_avatar': '',
    'status': 'open',
    'start_date': '2024-01-01T00:00:00Z',
    'location': 'Mountain',
    'description': 'A test trip',
    'max_members': 10,
    'application_count': 0,
    'total_application_count': 0,
    'approval_required': false,
    'private_message': '',
    'like_count': 0,
    'comment_count': 0,
    'is_liked': false,
    'latest_comments': [],
    'created_at': '2024-01-01T00:00:00Z',
    'created_by': 'u1',
    'updated_at': '2024-01-01T00:00:00Z',
    'updated_by': 'u1',
  });

  group('GroupEventRemoteDataSource.getEvents', () {
    test('returns list of events on success', () async {
      when(() => mockApiService.listEvents(any())).thenAnswer((_) async => [testEventResponse]);

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

      when(() => mockApiService.createEvent(any())).thenAnswer((_) async => testEventResponse);

      final result = await dataSource.createEvent(event);

      expect(result, 'evt-999');
    });

    test('deleteEvent calls delete', () async {
      when(() => mockApiService.deleteEvent('evt-1')).thenAnswer((_) async {});

      await dataSource.deleteEvent(eventId: 'evt-1', userId: 'u1');

      verify(() => mockApiService.deleteEvent('evt-1')).called(1);
    });
  });

  group('Application and Comments', () {
    test('applyEvent returns application ID', () async {
      final appResponse = GroupEventApplicationResponse.fromJson({
        'id': 'app-123',
        'event_id': 'evt-1',
        'user_id': 'u1',
        'message': 'Pick me!',
        'status': 'pending',
        'user_name': 'Test',
        'user_avatar': '',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'updated_by': 'u1',
      });

      when(() => mockApiService.applyEvent('evt-1', any())).thenAnswer((_) async => appResponse);

      final result = await dataSource.applyEvent(eventId: 'evt-1', userId: 'u1', message: 'Pick me!');

      expect(result, 'app-123');
    });

    test('addComment returns comment object', () async {
      final commentResponse = GroupEventCommentResponse.fromJson({
        'id': 'c1',
        'event_id': 'e1',
        'user_id': 'u1',
        'content': 'Nice!',
        'user_name': 'Test User',
        'user_avatar': '🐻',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });

      when(() => mockApiService.addComment('e1', any())).thenAnswer((_) async => commentResponse);

      final result = await dataSource.addComment(eventId: 'e1', userId: 'u1', content: 'Nice!');

      expect(result.content, 'Nice!');
      expect(result.id, 'c1');
    });
  });
}
