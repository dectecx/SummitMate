import 'package:injectable/injectable.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../core/di/injection.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../models/poll.dart';
import '../interfaces/i_poll_remote_data_source.dart';

/// 投票的遠端資料來源實作
@LazySingleton(as: IPollRemoteDataSource)
class PollRemoteDataSource implements IPollRemoteDataSource {
  static const String _source = 'PollRemoteDataSource';

  final NetworkAwareClient _apiClient;

  PollRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得行程投票列表
  ///
  /// [tripId] 行程 ID
  @override
  Future<List<Poll>> getPolls(String tripId) async {
    try {
      LogService.info('獲取行程投票列表: $tripId', source: _source);

      final response = await _apiClient.get('/trips/$tripId/polls');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> pollsJson = response.data as List<dynamic>;
      LogService.info('已獲取 ${pollsJson.length} 個投票', source: _source);

      return pollsJson.map((e) => Poll.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      LogService.error('getPolls 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 建立新投票
  ///
  /// [tripId] 行程 ID
  /// [title] 標題
  /// [description] 內容說明
  /// [deadline] 截止時間
  /// [isAllowAddOption] 是否允許自行新增選項
  /// [maxOptionLimit] 總選項上限
  /// [allowMultipleVotes] 是否允許多選
  /// [initialOptions] 初始選項內容
  @override
  Future<String> createPoll({
    required String tripId,
    required String title,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    try {
      LogService.info('建立新投票: $title', source: _source);

      final payload = {
        'title': title,
        'description': description,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        'initial_options': initialOptions,
        'is_allow_add_option': isAllowAddOption,
        'max_option_limit': maxOptionLimit,
        'allow_multiple_votes': allowMultipleVotes,
        'result_display_type': 'realtime', // 目前固定為即時顯示
      };

      final response = await _apiClient.post('/trips/$tripId/polls', data: payload);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      return response.data['id'] as String? ?? '';
    } catch (e) {
      LogService.error('createPoll 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 投票操作
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [optionId] 目標選項 ID
  @override
  Future<void> voteOption({required String tripId, required String pollId, required String optionId}) async {
    try {
      LogService.info('投票操作: $pollId, 選項: $optionId', source: _source);

      final response = await _apiClient.post('/trips/$tripId/polls/$pollId/options/$optionId/vote');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('voteOption 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 新增投票選項
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [text] 選項文字內容
  @override
  Future<void> addOption({required String tripId, required String pollId, required String text}) async {
    try {
      LogService.info('新增投票選項 "$text" 至投票 $pollId', source: _source);

      final payload = {'text': text};
      final response = await _apiClient.post('/trips/$tripId/polls/$pollId/options', data: payload);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('addOption 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除指定投票
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  @override
  Future<void> deletePoll({required String tripId, required String pollId}) async {
    try {
      LogService.info('刪除投票: $pollId', source: _source);

      final response = await _apiClient.delete('/trips/$tripId/polls/$pollId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deletePoll 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除指定選項
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [optionId] 選項 ID
  @override
  Future<void> deleteOption({required String tripId, required String pollId, required String optionId}) async {
    try {
      LogService.info('刪除投票選項: $optionId', source: _source);

      final response = await _apiClient.delete('/trips/$tripId/polls/$pollId/options/$optionId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deleteOption 失敗: $e', source: _source);
      rethrow;
    }
  }
}
