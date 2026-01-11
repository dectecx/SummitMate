import '../clients/network_aware_client.dart';
import '../clients/gas_api_client.dart';
import '../../core/di.dart';
import '../../core/constants.dart';
import '../../data/models/poll.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_poll_service.dart';

class PollService implements IPollService {
  // 若有需要可使用 Singleton，或保持目前的依賴注入方式
  static const String _source = 'PollService';

  final NetworkAwareClient _apiClient;

  PollService({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得所有投票列表
  @override
  Future<List<Poll>> getPolls({required String userId}) async {
    try {
      LogService.info('Fetching polls for user: $userId', source: _source);
      final response = await _apiClient.get(queryParams: {'action': ApiConfig.actionPollList, 'user_id': userId});

      LogService.debug('Fetch response status: ${response.statusCode}', source: _source);

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
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

  /// 建立新投票
  @override
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
      'action': ApiConfig.actionPollCreate,
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
      LogService.debug('Create response: ${response.data}', source: _source);

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
    } catch (e) {
      LogService.error('Error creating poll: $e', source: _source);
      rethrow;
    }
  }

  /// 對選項投票
  @override
  Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async {
    final payload = {
      'action': ApiConfig.actionPollVote,
      'poll_id': pollId,
      'option_ids': optionIds,
      'user_id': userId,
      'user_name': userName,
    };

    try {
      LogService.info('Voting on poll: $pollId, options: $optionIds', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Vote response: ${response.data}', source: _source);

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
    } catch (e) {
      LogService.error('Error voting: $e', source: _source);
      rethrow;
    }
  }

  /// 新增選項
  @override
  Future<void> addOption({required String pollId, required String text, required String creatorId}) async {
    final payload = {'action': ApiConfig.actionPollAddOption, 'poll_id': pollId, 'text': text, 'creator_id': creatorId};

    try {
      LogService.info('Adding option "$text" to poll $pollId by creator $creatorId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Add option response: ${response.data}', source: _source);

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Option added successfully to poll $pollId.', source: _source);
    } catch (e) {
      LogService.error('Error adding option: $e', source: _source);
      rethrow;
    }
  }

  /// 關閉投票
  @override
  Future<void> closePoll({required String pollId, required String userId}) async {
    final payload = {'action': ApiConfig.actionPollClose, 'poll_id': pollId, 'user_id': userId};

    try {
      LogService.info('Closing poll: $pollId by user: $userId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Close response: ${response.data}', source: _source);

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Poll $pollId closed successfully.', source: _source);
    } catch (e) {
      LogService.error('Error closing poll: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除投票
  @override
  Future<void> deletePoll({required String pollId, required String userId}) async {
    final payload = {'action': ApiConfig.actionPollDelete, 'poll_id': pollId, 'user_id': userId};

    try {
      LogService.info('Deleting poll: $pollId by user: $userId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Delete response: ${response.data}', source: _source);

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
      LogService.info('Poll $pollId deleted successfully.', source: _source);
    } catch (e) {
      LogService.error('Error deleting poll: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除選項
  @override
  Future<void> deleteOption({required String optionId, required String userId}) async {
    final payload = {'action': ApiConfig.actionPollDeleteOption, 'option_id': optionId, 'user_id': userId};

    try {
      LogService.info('Deleting option: $optionId by user: $userId', source: _source);
      final response = await _apiClient.post(payload);
      LogService.debug('Delete option response: ${response.data}', source: _source);

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
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
