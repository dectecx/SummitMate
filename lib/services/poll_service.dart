import 'dart:convert';
import 'gas_api_client.dart';
import '../core/env_config.dart';
import '../core/constants.dart';
import '../data/models/poll.dart';
import 'log_service.dart';

class PollService {
  // Use a singleton pattern if desired, or just static methods
  // Using static methods for simplicity as in other services

  static const String _source = 'PollService';

  final GasApiClient _apiClient;

  PollService({GasApiClient? apiClient}) : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.getApiUrl());

  /// Fetch all polls
  Future<List<Poll>> fetchPolls({required String userId}) async {
    try {
      LogService.info('Fetching polls for user: $userId', source: _source);
      final response = await _apiClient.get(
        queryParams: {'action': ApiConfig.actionPoll, 'subAction': 'get', 'user_id': userId},
      );

      LogService.debug('Fetch response status: ${response.statusCode}', source: _source);

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJsonString(utf8.decode(response.bodyBytes));
        LogService.debug('Response parsed: code=${gasResponse.code}, message=${gasResponse.message}', source: _source);

        if (gasResponse.isSuccess) {
          final List<dynamic> pollsJson = gasResponse.data['polls'] ?? [];
          LogService.info('Fetched ${pollsJson.length} polls successfully', source: _source);
          return pollsJson.map((e) => Poll.fromJson(e)).toList();
        } else {
          LogService.error('Fetch polls failed: [${gasResponse.code}] ${gasResponse.message}', source: _source);
          throw Exception(gasResponse.message);
        }
      } else {
        LogService.error('Fetch polls HTTP error: ${response.statusCode}', source: _source);
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('Error fetching polls: $e', source: _source);
      rethrow;
    }
  }

  /// Create a new poll
  Future<void> createPoll({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'create',
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'created_at': DateTime.now().toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'initial_options': initialOptions,
      'config': {
        'is_allow_add_option': isAllowAddOption,
        'max_option_limit': maxOptionLimit,
        'allow_multiple_votes': allowMultipleVotes,
        'result_display_type': 'realtime',
      },
    };

    try {
      LogService.info('Creating poll: $title', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Create response: ${response.body}', source: _source);

      final gasResponse = GasApiResponse.fromJsonString(response.body);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
    } catch (e) {
      LogService.error('Error creating poll: $e', source: _source);
      rethrow;
    }
  }

  /// Vote for options
  Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async {
    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'vote',
      'poll_id': pollId,
      'option_ids': optionIds,
      'user_id': userId,
      'user_name': userName,
    };

    try {
      LogService.info('Voting on poll: $pollId, options: $optionIds', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Vote response: ${response.body}', source: _source);

      final gasResponse = GasApiResponse.fromJsonString(response.body);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
    } catch (e) {
      LogService.error('Error voting: $e', source: _source);
      rethrow;
    }
  }

  /// Add a new option
  Future<void> addOption({required String pollId, required String text, required String creatorId}) async {
    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'add_option',
      'poll_id': pollId,
      'text': text,
      'creator_id': creatorId,
    };

    try {
      LogService.info('Adding option "$text" to poll $pollId by creator $creatorId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Add option response: ${response.body}', source: _source);

      final gasResponse = GasApiResponse.fromJsonString(response.body);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Option added successfully to poll $pollId.', source: _source);
    } catch (e) {
      LogService.error('Error adding option: $e', source: _source);
      rethrow;
    }
  }

  /// Close a poll (mark as ended)
  Future<void> closePoll({required String pollId, required String userId}) async {
    final payload = {'action': ApiConfig.actionPoll, 'subAction': 'close', 'poll_id': pollId, 'user_id': userId};

    try {
      LogService.info('Closing poll: $pollId by user: $userId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Close response: ${response.body}', source: _source);

      final gasResponse = GasApiResponse.fromJsonString(response.body);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Poll $pollId closed successfully.', source: _source);
    } catch (e) {
      LogService.error('Error closing poll: $e', source: _source);
      rethrow;
    }
  }

  /// Delete a poll
  Future<void> deletePoll({required String pollId, required String userId}) async {
    final payload = {'action': ApiConfig.actionPoll, 'subAction': 'delete', 'poll_id': pollId, 'user_id': userId};

    try {
      LogService.info('Deleting poll: $pollId by user: $userId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Delete response: ${response.body}', source: _source);

      final gasResponse = GasApiResponse.fromJsonString(response.body);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Poll $pollId deleted successfully.', source: _source);
    } catch (e) {
      LogService.error('Error deleting poll: $e', source: _source);
      rethrow;
    }
  }

  /// Delete an option
  Future<void> deleteOption({required String optionId, required String userId}) async {
    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'delete_option',
      'option_id': optionId,
      'user_id': userId,
    };

    try {
      LogService.info('Deleting option: $optionId by user: $userId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Delete option response: ${response.body}', source: _source);

      final gasResponse = GasApiResponse.fromJsonString(response.body);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Option $optionId deleted successfully.', source: _source);
    } catch (e) {
      LogService.error('Error deleting option: $e', source: _source);
      rethrow;
    }
  }
}
