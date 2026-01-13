import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/core/constants.dart';
import 'package:summitmate/infrastructure/clients/gas_api_client.dart';
import 'package:summitmate/infrastructure/services/poll_service.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/core/error/result.dart'; // Added import

// ============================================================
// === MOCKS ===
// ============================================================

/// Mock GasApiClient for testing PollService
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? mockResponseData;
  String mockResponseCode = '0000';
  String mockResponseMessage = 'Success';
  bool shouldThrowError = false;

  Map<String, dynamic>? lastGetParams;
  Map<String, dynamic>? lastPostBody;

  @override
  Future<Response> get({Map<String, String>? queryParams}) async {
    lastGetParams = queryParams;

    if (shouldThrowError) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Network error',
      );
    }

    final responseBody = {'code': mockResponseCode, 'message': mockResponseMessage, 'data': mockResponseData ?? {}};

    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: 200,
    );
  }

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    lastPostBody = body;

    if (shouldThrowError) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Network error',
      );
    }

    final responseBody = {'code': mockResponseCode, 'message': mockResponseMessage, 'data': mockResponseData ?? {}};

    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: 200,
    );
  }
}

class MockConnectivityService extends Mock implements IConnectivityService {}

// ============================================================
// === TEST DATA ===
// ============================================================

Map<String, dynamic> createPollJson({String id = 'poll-1', String title = 'Test Poll', String status = 'active'}) {
  return {
    'id': id,
    'title': title,
    'description': 'Test description',
    'creator_id': 'user-1',
    'created_at': '2025-01-01T00:00:00.000Z',
    'deadline': null,
    'is_allow_add_option': false,
    'max_option_limit': 20,
    'allow_multiple_votes': false,
    'result_display_type': 'realtime',
    'status': status,
    'options': [],
    'my_votes': [],
    'total_votes': 0,
  };
}

// ============================================================
// === TESTS ===
// ============================================================

void main() {
  late PollService pollService;
  late MockGasApiClient mockClient;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockClient = MockGasApiClient();
    mockConnectivity = MockConnectivityService();
    when(() => mockConnectivity.isOffline).thenReturn(false);

    final networkClient = NetworkAwareClient(apiClient: mockClient, connectivity: mockConnectivity);
    pollService = PollService(apiClient: networkClient);
  });

  group('PollService.getPolls', () {
    test('returns list of polls on success', () async {
      mockClient.mockResponseData = {
        'polls': [createPollJson(id: 'poll-1', title: 'Poll 1'), createPollJson(id: 'poll-2', title: 'Poll 2')],
      };

      final result = await pollService.getPolls(userId: 'user-1');

      expect(result, isA<Success>());
      final polls = (result as Success).value;
      expect(polls, hasLength(2));
      expect(polls[0].title, 'Poll 1');
      expect(polls[1].title, 'Poll 2');
      expect(mockClient.lastGetParams?['user_id'], 'user-1');
    });

    test('returns empty list when no polls exist', () async {
      mockClient.mockResponseData = {'polls': []};

      final result = await pollService.getPolls(userId: 'user-1');

      expect(result, isA<Success>());
      expect((result as Success).value, isEmpty);
    });

    test('returns Failure on API error', () async {
      mockClient.mockResponseCode = '9999';
      mockClient.mockResponseMessage = 'Server error';

      final result = await pollService.getPolls(userId: 'user-1');

      expect(result, isA<Failure>());
    });

    test('returns Failure on network error', () async {
      mockClient.shouldThrowError = true;

      final result = await pollService.getPolls(userId: 'user-1');

      expect(result, isA<Failure>());
    });
  });

  group('PollService.createPoll', () {
    test('creates poll successfully', () async {
      mockClient.mockResponseData = {};

      final result = await pollService.createPoll(
        title: 'New Poll',
        description: 'Description',
        creatorId: 'user-1',
        initialOptions: ['Option 1', 'Option 2'],
      );

      expect(result, isA<Success>());
      expect(mockClient.lastPostBody?['title'], 'New Poll');
      expect(mockClient.lastPostBody?['description'], 'Description');
      expect(mockClient.lastPostBody?['creator_id'], 'user-1');
      expect(mockClient.lastPostBody?['initial_options'], ['Option 1', 'Option 2']);
    });

    test('returns Failure on API error', () async {
      mockClient.mockResponseCode = '9999';
      mockClient.mockResponseMessage = 'Creation failed';

      final result = await pollService.createPoll(title: 'New Poll', creatorId: 'user-1');

      expect(result, isA<Failure>());
    });
  });

  group('PollService.votePoll', () {
    test('votes successfully', () async {
      mockClient.mockResponseData = {};

      final result = await pollService.votePoll(
        pollId: 'poll-1',
        optionIds: ['opt-1', 'opt-2'],
        userId: 'user-1',
        userName: 'Alice',
      );

      expect(result, isA<Success>());
      expect(mockClient.lastPostBody?['poll_id'], 'poll-1');
      expect(mockClient.lastPostBody?['option_ids'], ['opt-1', 'opt-2']);
      expect(mockClient.lastPostBody?['user_id'], 'user-1');
      expect(mockClient.lastPostBody?['user_name'], 'Alice');
    });

    test('returns Failure on already voted error', () async {
      mockClient.mockResponseCode = '4001';
      mockClient.mockResponseMessage = 'Already voted';

      final result = await pollService.votePoll(pollId: 'poll-1', optionIds: ['opt-1'], userId: 'user-1');

      expect(result, isA<Failure>());
    });
  });

  group('PollService.addOption', () {
    test('adds option successfully', () async {
      mockClient.mockResponseData = {};

      final result = await pollService.addOption(pollId: 'poll-1', text: 'New Option', creatorId: 'user-1');

      expect(result, isA<Success>());
      expect(mockClient.lastPostBody?['poll_id'], 'poll-1');
      expect(mockClient.lastPostBody?['text'], 'New Option');
      expect(mockClient.lastPostBody?['creator_id'], 'user-1');
    });

    test('returns Failure on limit exceeded', () async {
      mockClient.mockResponseCode = '4002';
      mockClient.mockResponseMessage = 'Option limit exceeded';

      final result = await pollService.addOption(pollId: 'poll-1', text: 'New Option', creatorId: 'user-1');

      expect(result, isA<Failure>());
    });
  });

  group('PollService.closePoll', () {
    test('closes poll successfully', () async {
      mockClient.mockResponseData = {};

      final result = await pollService.closePoll(pollId: 'poll-1', userId: 'user-1');

      expect(result, isA<Success>());
      expect(mockClient.lastPostBody?['poll_id'], 'poll-1');
      expect(mockClient.lastPostBody?['action'], ApiConfig.actionPollClose);
    });

    test('returns Failure on unauthorized', () async {
      mockClient.mockResponseCode = '4003';
      mockClient.mockResponseMessage = 'Not authorized';

      final result = await pollService.closePoll(pollId: 'poll-1', userId: 'user-2');

      expect(result, isA<Failure>());
    });
  });

  group('PollService.deletePoll', () {
    test('deletes poll successfully', () async {
      mockClient.mockResponseData = {};

      final result = await pollService.deletePoll(pollId: 'poll-1', userId: 'user-1');

      expect(result, isA<Success>());
      expect(mockClient.lastPostBody?['poll_id'], 'poll-1');
      expect(mockClient.lastPostBody?['action'], ApiConfig.actionPollDelete);
    });

    test('returns Failure on not found', () async {
      mockClient.mockResponseCode = '4004';
      mockClient.mockResponseMessage = 'Poll not found';

      final result = await pollService.deletePoll(pollId: 'invalid', userId: 'user-1');

      expect(result, isA<Failure>());
    });
  });

  group('PollService.deleteOption', () {
    test('deletes option successfully', () async {
      mockClient.mockResponseData = {};

      final result = await pollService.deleteOption(optionId: 'opt-1', userId: 'user-1');

      expect(result, isA<Success>());
      expect(mockClient.lastPostBody?['option_id'], 'opt-1');
      expect(mockClient.lastPostBody?['action'], ApiConfig.actionPollDeleteOption);
    });
  });
}
