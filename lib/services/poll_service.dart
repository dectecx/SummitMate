import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/env_config.dart';
import '../core/constants.dart';
import '../data/models/poll.dart';
import 'log_service.dart';

class PollService {
  // Use a singleton pattern if desired, or just static methods
  // Using static methods for simplicity as in other services

  static const String _source = 'PollService';
  
  // For testing
  static http.Client _client = http.Client();
  static set client(http.Client client) => _client = client;

  // Base URL override for testing
  static String? _testBaseUrl;
  static set testBaseUrl(String? url) => _testBaseUrl = url;

  static String get _apiBaseUrl => _testBaseUrl ?? EnvConfig.getApiUrl();

  // Helper to get device/user ID
  // In a real app, this should come from a AuthProvider or UserSettings
  // For now, we reuse the logic from MessageService or just generate/store one locally
  // But wait, the API requires a consistent ID to track "My Votes".
  // We should accept userId as a parameter.

  /// Fetch all polls
  static Future<List<Poll>> fetchPolls({required String userId}) async {
    final url = Uri.parse('$_apiBaseUrl?action=${ApiConfig.actionPoll}&subAction=get&user_id=$userId');

    try {
      debugPrint('[$_source] Fetching polls for user: $userId');
      final response = await _client.get(url);
      debugPrint('[$_source] Fetch response status: ${response.statusCode}');

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
  static Future<void> createPoll({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    final url = Uri.parse(_apiBaseUrl);

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
      debugPrint('[$_source] Creating poll: $title');
      final response = await _client.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(payload));
      debugPrint('[$_source] Create response: ${response.body}');

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
  static Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async {
    final url = Uri.parse(_apiBaseUrl);

    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'vote',
      'poll_id': pollId,
      'option_ids': optionIds,
      'user_id': userId,
      'user_name': userName,
    };

    try {
      debugPrint('[$_source] Voting on poll: $pollId, options: $optionIds');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint('[$_source] Vote response: ${response.body}');

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
  static Future<void> addOption({required String pollId, required String text, required String creatorId}) async {
    final url = Uri.parse(_apiBaseUrl);

    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'add_option',
      'poll_id': pollId,
      'text': text,
      'creator_id': creatorId,
    };

    try {
      debugPrint('[$_source] Adding option "$text" to poll $pollId by creator $creatorId');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint('[$_source] Add option response: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      debugPrint('[$_source] Option added successfully to poll $pollId.');
    } catch (e) {
      LogService.error('Error adding option: $e', source: _source);
      rethrow;
    }
  }

  /// Close a poll (mark as ended)
  static Future<void> closePoll({required String pollId, required String userId}) async {
    final url = Uri.parse(_apiBaseUrl);
    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'close',
      'poll_id': pollId,
      'user_id': userId,
    };

    try {
      debugPrint('[$_source] Closing poll: $pollId by user: $userId');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint('[$_source] Close response: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      debugPrint('[$_source] Poll $pollId closed successfully.');
    } catch (e) {
      LogService.error('Error closing poll: $e', source: _source);
      rethrow;
    }
  }

  /// Delete a poll
  static Future<void> deletePoll({required String pollId, required String userId}) async {
    final url = Uri.parse(_apiBaseUrl);
    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'delete',
      'poll_id': pollId,
      'user_id': userId,
    };

    try {
      debugPrint('[$_source] Deleting poll: $pollId by user: $userId');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint('[$_source] Delete response: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      debugPrint('[$_source] Poll $pollId deleted successfully.');
    } catch (e) {
      LogService.error('Error deleting poll: $e', source: _source);
      rethrow;
    }
  }

  /// Delete an option
  static Future<void> deleteOption({required String optionId, required String userId}) async {
    final url = Uri.parse(_apiBaseUrl);

    final payload = {
      'action': ApiConfig.actionPoll,
      'subAction': 'delete_option',
      'option_id': optionId,
      'user_id': userId,
    };

    try {
      debugPrint('[$_source] Deleting option: $optionId by user: $userId');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint('[$_source] Delete option response: ${response.body}');

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
      debugPrint('[$_source] Option $optionId deleted successfully.');
    } catch (e) {
      LogService.error('Error deleting option: $e', source: _source);
      rethrow;
    }
  }
}
