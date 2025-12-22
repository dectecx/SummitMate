import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:summitmate/services/poll_service.dart';
import 'package:summitmate/data/models/poll.dart';
import 'package:summitmate/core/env_config.dart';

// Generate MockClient
@GenerateMocks([http.Client])
import 'poll_service_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late PollService pollService;

  setUp(() {
    mockClient = MockClient();
    pollService = PollService(
      client: mockClient,
      baseUrl: 'https://mock.api',
    );
  });

  group('PollService', () {
    const String userId = 'test_user_1';
    const String pollId = 'poll_123';

    test('fetchPolls returns list of Polls if call completes successfully', () async {
      final mockResponse = {
        'success': true,
        'polls': [
          {
            'poll_id': '1',
            'title': 'Test Poll',
            'description': 'Desc',
            'creator_id': 'creator1',
            'created_at': '2023-01-01T00:00:00.000Z',
            'deadline': null,
            'is_allow_add_option': false,
            'max_option_limit': 10,
            'allow_multiple_votes': false,
            'result_display_type': 'realtime',
            'status': 'active',
            'total_votes': 5,
            'options': [],
            'my_votes': []
          }
        ]
      };

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      final polls = await pollService.fetchPolls(userId: userId);

      expect(polls, isA<List<Poll>>());
      expect(polls.length, 1);
      expect(polls.first.title, 'Test Poll');
      verify(mockClient.get(any)).called(1);
    });

    test('fetchPolls throws Exception on error response', () async {
       final mockResponse = {
        'success': false,
        'error': 'Database error'
      };

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      expect(pollService.fetchPolls(userId: userId), throwsException);
    });

    test('createPoll posts correct data and completes successfully', () async {
      final mockResponse = {'success': true};

      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      await pollService.createPoll(
        title: 'New Poll',
        creatorId: userId,
        description: 'Test description',
      );

      verify(mockClient.post(
        any,
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).called(1);
    });

    test('votePoll posts correct data and completes successfully', () async {
      final mockResponse = {'success': true};

      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      await pollService.votePoll(
        pollId: pollId,
        optionIds: ['opt1'],
        userId: userId,
      );

      verify(mockClient.post(
        any,
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).called(1);
    });
  });
}
