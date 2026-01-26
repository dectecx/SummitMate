import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/clients/gas_api_client.dart';
import '../../../core/di.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../models/poll.dart';
import '../interfaces/i_poll_remote_data_source.dart';

/// 投票遠端資料來源實作 (GAS API)
class PollRemoteDataSource implements IPollRemoteDataSource {
  static const String _source = 'PollRemoteDataSource';

  final NetworkAwareClient _apiClient;

  PollRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  @override
  Future<List<Poll>> getPolls({required String userId}) async {
    LogService.info('Fetching polls for user: $userId', source: _source);
    final response = await _apiClient.get('', queryParameters: {'action': ApiConfig.actionPollList, 'user_id': userId});

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    final List<dynamic> pollsJson = gasResponse.data['polls'] ?? [];
    LogService.info('Fetched ${pollsJson.length} polls', source: _source);
    return pollsJson.map((e) => Poll.fromJson(e)).toList();
  }

  @override
  Future<String> createPoll({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    LogService.info('Creating poll: $title', source: _source);
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

    final response = await _apiClient.post('', data: payload);
    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    return gasResponse.data['id'] as String? ?? '';
  }

  @override
  Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async {
    LogService.info('Voting on poll: $pollId, options: $optionIds', source: _source);
    final payload = {
      'action': ApiConfig.actionPollVote,
      'poll_id': pollId,
      'option_ids': optionIds,
      'user_id': userId,
      'user_name': userName,
    };

    final response = await _apiClient.post('', data: payload);
    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> addOption({required String pollId, required String text, required String creatorId}) async {
    LogService.info('Adding option "$text" to poll $pollId', source: _source);
    final payload = {'action': ApiConfig.actionPollAddOption, 'poll_id': pollId, 'text': text, 'creator_id': creatorId};

    final response = await _apiClient.post('', data: payload);
    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> closePoll({required String pollId, required String userId}) async {
    LogService.info('Closing poll: $pollId', source: _source);
    final payload = {'action': ApiConfig.actionPollClose, 'poll_id': pollId, 'user_id': userId};

    final response = await _apiClient.post('', data: payload);
    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> deletePoll({required String pollId, required String userId}) async {
    LogService.info('Deleting poll: $pollId', source: _source);
    final payload = {'action': ApiConfig.actionPollDelete, 'poll_id': pollId, 'user_id': userId};

    final response = await _apiClient.post('', data: payload);
    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> deleteOption({required String optionId, required String userId}) async {
    LogService.info('Deleting option: $optionId', source: _source);
    final payload = {'action': ApiConfig.actionPollDeleteOption, 'option_id': optionId, 'user_id': userId};

    final response = await _apiClient.post('', data: payload);
    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }
}
