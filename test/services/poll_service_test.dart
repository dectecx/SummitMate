import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/services/poll_service.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:summitmate/data/models/poll.dart';

// Mock GasApiClient
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? expectedResponseData;
  bool shouldFail = false;
  int statusCode = 200;
  Map<String, dynamic>? capturedBody;

  @override
  Future<Response> get({Map<String, String>? queryParams}) async {
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Internal Server Error',
      );
    }

    final responseBody = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };
    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: statusCode,
    );
  }

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    capturedBody = body;
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Internal Server Error',
      );
    }
    final responseBody = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };

    // Simulate specific Poll response structure (create/vote returns empty data but success code)
    // If expectedResponseData is set, iterate and add it to response

    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: statusCode,
    );
  }
}

void main() {
  late MockGasApiClient mockClient;
  late PollService pollService;

  setUp(() {
    mockClient = MockGasApiClient();
    pollService = PollService(apiClient: mockClient);
  });

  group('PollService', () {
    const String userId = 'test_user_1';
    const String pollId = 'poll_123';

    test('fetchPolls returns list of Polls if call completes successfully', () async {
      mockClient.expectedResponseData = {
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
            'my_votes': [],
          },
        ],
      };

      final polls = await pollService.fetchPolls(userId: userId);

      expect(polls, isA<List<Poll>>());
      expect(polls.length, 1);
      expect(polls.first.title, 'Test Poll');
    });

    test('fetchPolls throws Exception on error response', () async {
      mockClient.shouldFail = true;
      expect(() => pollService.fetchPolls(userId: userId), throwsA(anything));
    });

    test('createPoll posts correct data and completes successfully', () async {
      // Setup success response
      mockClient.expectedResponseData = {};

      await pollService.createPoll(title: 'New Poll', creatorId: userId, description: 'Test description');

      expect(mockClient.capturedBody, isNotNull);
      expect(mockClient.capturedBody!['action'], 'poll');
      expect(mockClient.capturedBody!['subAction'], 'create');
      expect(mockClient.capturedBody!['title'], 'New Poll');
    });

    test('votePoll posts correct data and completes successfully', () async {
      mockClient.expectedResponseData = {};

      await pollService.votePoll(pollId: pollId, optionIds: ['opt1'], userId: userId);

      expect(mockClient.capturedBody, isNotNull);
      expect(mockClient.capturedBody!['action'], 'poll');
      expect(mockClient.capturedBody!['subAction'], 'vote');
    });
  });
}
