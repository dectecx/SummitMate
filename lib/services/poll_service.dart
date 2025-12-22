import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/env_config.dart';
import '../core/constants.dart';
import '../data/models/poll.dart';
import 'log_service.dart';

class PollService {
  // Use a singleton pattern if desired, or just static methods
  // Using static methods for simplicity as in other services

  static const String _source = 'PollService';

  final http.Client _client;
  final String _baseUrl;

  PollService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? EnvConfig.getApiUrl();

  // Helper to get device/user ID
  // In a real app, this should come from a AuthProvider or UserSettings
  // For now, we reuse the logic from MessageService or just generate/store one locally
  // But wait, the API requires a consistent ID to track "My Votes".
  // We should accept userId as a parameter.

  /// Closed poll icon: Icons.lock_clock (or similar)

  /// Fetch all polls
  Future<List<Poll>> fetchPolls({required String userId}) async {
    final url = Uri.parse('$_baseUrl?action=${ApiConfig.actionPoll}&subAction=get&user_id=$userId');

    try {
      LogService.info('Fetching polls for user: $userId', source: _source);
      final response = await _client.get(url);
      LogService.debug('Fetch response status: ${response.statusCode}', source: _source);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        if (jsonResponse['success'] == true) {
          final List<dynamic> pollsJson = jsonResponse['polls'];
          return pollsJson.map((e) => Poll.fromJson(e)).toList();
        } else {
          LogService.error('Fetch polls failed: ${jsonResponse['error']}', source: _source);
          throw Exception(jsonResponse['error']);
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
    final url = Uri.parse(_baseUrl);

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
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      LogService.debug('Create response: ${response.body}', source: _source);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
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
    final url = Uri.parse(_baseUrl);

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
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      LogService.debug('Vote response: ${response.body}', source: _source);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
    } catch (e) {
      LogService.error('Error voting: $e', source: _source);
      rethrow;
    }
  }

  /// Add a new option
  Future<void> addOption({required String pollId, required String text, required String creatorId}) async {
    final url = Uri.parse(_baseUrl);

    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'add_option',
      'poll_id': pollId,
      'text': text,
      'creator_id': creatorId,
    };

    try {
      LogService.info('Adding option "$text" to poll $pollId by creator $creatorId', source: _source);
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      LogService.debug('Add option response: ${response.body}', source: _source);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      LogService.info('Option added successfully to poll $pollId.', source: _source);
    } catch (e) {
      LogService.error('Error adding option: $e', source: _source);
      rethrow;
    }
  }

  /// Close a poll (mark as ended)
  Future<void> closePoll({required String pollId, required String userId}) async {
    final url = Uri.parse(_baseUrl);
    final payload = {'action': ApiConfig.actionPoll, 'subAction': 'close', 'poll_id': pollId, 'user_id': userId};

    try {
      LogService.info('Closing poll: $pollId by user: $userId', source: _source);
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      LogService.debug('Close response: ${response.body}', source: _source);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      LogService.info('Poll $pollId closed successfully.', source: _source);
    } catch (e) {
      LogService.error('Error closing poll: $e', source: _source);
      rethrow;
    }
  }

  /// Delete a poll
  Future<void> deletePoll({required String pollId, required String userId}) async {
    final url = Uri.parse(_baseUrl);
    final payload = {'action': ApiConfig.actionPoll, 'subAction': 'delete', 'poll_id': pollId, 'user_id': userId};

    try {
      LogService.info('Deleting poll: $pollId by user: $userId', source: _source);
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      LogService.debug('Delete response: ${response.body}', source: _source);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      LogService.info('Poll $pollId deleted successfully.', source: _source);
    } catch (e) {
      LogService.error('Error deleting poll: $e', source: _source);
      rethrow;
    }
  }

  /// Delete an option
  Future<void> deleteOption({required String optionId, required String userId}) async {
    final url = Uri.parse(_baseUrl);

    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'delete_option',
      'option_id': optionId,
      'user_id': userId,
    };

    try {
      LogService.info('Deleting option: $optionId by user: $userId', source: _source);
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      LogService.debug('Delete option response: ${response.body}', source: _source);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      LogService.info('Option $optionId deleted successfully.', source: _source);
    } catch (e) {
      LogService.error('Error deleting option: $e', source: _source);
      rethrow;
    }
  }
}
