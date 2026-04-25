import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/poll_api_models.dart';
import 'package:summitmate/data/api/services/poll_api_service.dart';
import 'package:summitmate/data/datasources/remote/poll_remote_data_source.dart';

class MockPollApiService extends Mock implements PollApiService {}

class FakePollCreateRequest extends Fake implements PollCreateRequest {}

class FakePollOptionRequest extends Fake implements PollOptionRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePollCreateRequest());
    registerFallbackValue(FakePollOptionRequest());
  });

  late PollRemoteDataSource dataSource;
  late MockPollApiService mockApiService;

  setUp(() {
    mockApiService = MockPollApiService();
    dataSource = PollRemoteDataSource(mockApiService);
  });

  final testPollResponse = PollResponse.fromJson({
    'id': 'poll-1',
    'trip_id': 'trip-1',
    'title': 'Test Poll',
    'description': '',
    'creator_id': 'user-1',
    'is_allow_add_option': true,
    'max_option_limit': 10,
    'allow_multiple_votes': false,
    'result_display_type': 'always',
    'status': 'active',
    'options': [],
    'my_votes': [],
    'total_votes': 0,
    'created_at': '2024-01-01T00:00:00Z',
    'created_by': 'user-1',
    'updated_at': '2024-01-01T00:00:00Z',
    'updated_by': 'user-1',
  });

  group('PollRemoteDataSource.getPolls', () {
    test('returns list of polls on success', () async {
      when(() => mockApiService.listPolls('trip-1')).thenAnswer((_) async => [testPollResponse]);

      final result = await dataSource.getPolls('trip-1');

      expect(result.length, 1);
      expect(result[0].id, 'poll-1');
      expect(result[0].title, 'Test Poll');
    });
  });

  group('PollRemoteDataSource.createPoll', () {
    test('returns new poll ID on success', () async {
      when(() => mockApiService.createPoll('trip-1', any())).thenAnswer((_) async => testPollResponse);

      final result = await dataSource.createPoll(
        tripId: 'trip-1',
        title: 'Test Poll',
        initialOptions: ['Op 1', 'Op 2'],
      );

      expect(result, 'poll-1');
      verify(() => mockApiService.createPoll('trip-1', any())).called(1);
    });
  });

  group('PollRemoteDataSource Operations', () {
    test('voteOption calls api correctly', () async {
      when(() => mockApiService.voteOption('t1', 'p1', 'o1')).thenAnswer((_) async {});

      await dataSource.voteOption(tripId: 't1', pollId: 'p1', optionId: 'o1');

      verify(() => mockApiService.voteOption('t1', 'p1', 'o1')).called(1);
    });

    test('addOption calls api correctly', () async {
      final optionResponse = PollOptionResponse.fromJson({
        'id': 'o1',
        'poll_id': 'p1',
        'text': 'New Case',
        'creator_id': 'u1',
        'vote_count': 0,
        'voters': [],
        'created_at': '2024-01-01T00:00:00Z',
        'created_by': 'u1',
        'updated_at': '2024-01-01T00:00:00Z',
        'updated_by': 'u1',
      });

      when(() => mockApiService.addOption('t1', 'p1', any())).thenAnswer((_) async => optionResponse);

      await dataSource.addOption(tripId: 't1', pollId: 'p1', text: 'New Case');

      verify(() => mockApiService.addOption('t1', 'p1', any())).called(1);
    });
  });
}
