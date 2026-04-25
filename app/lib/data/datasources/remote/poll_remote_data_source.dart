import 'package:injectable/injectable.dart';
import '../../models/poll.dart';
import '../../api/mappers/poll_api_mapper.dart';
import '../../api/models/poll_api_models.dart';
import '../../api/services/poll_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_poll_remote_data_source.dart';

/// 投票 (Poll) 的遠端資料來源實作
@LazySingleton(as: IPollRemoteDataSource)
class PollRemoteDataSource implements IPollRemoteDataSource {
  static const String _source = 'PollRemoteDataSource';

  final PollApiService _pollApi;

  PollRemoteDataSource(this._pollApi);

  @override
  Future<List<Poll>> getPolls(String tripId) async {
    try {
      LogService.info('獲取行程投票列表: $tripId', source: _source);
      final responses = await _pollApi.listPolls(tripId);
      final polls = responses.map(PollApiMapper.fromResponse).toList();
      LogService.info('已獲取 ${polls.length} 個投票', source: _source);
      return polls;
    } catch (e) {
      LogService.error('getPolls 失敗: $e', source: _source);
      rethrow;
    }
  }

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
      final request = PollCreateRequest(
        title: title,
        description: description,
        deadline: deadline,
        initialOptions: initialOptions,
        isAllowAddOption: isAllowAddOption,
        maxOptionLimit: maxOptionLimit,
        allowMultipleVotes: allowMultipleVotes,
        resultDisplayType: 'realtime',
      );
      final response = await _pollApi.createPoll(tripId, request);
      return response.id;
    } catch (e) {
      LogService.error('createPoll 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> voteOption({required String tripId, required String pollId, required String optionId}) async {
    try {
      LogService.info('投票操作: $pollId, 選項: $optionId', source: _source);
      await _pollApi.voteOption(tripId, pollId, optionId);
    } catch (e) {
      LogService.error('voteOption 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> addOption({required String tripId, required String pollId, required String text}) async {
    try {
      LogService.info('新增投票選項 "$text" 至投票 $pollId', source: _source);
      await _pollApi.addOption(tripId, pollId, PollOptionRequest(text: text));
    } catch (e) {
      LogService.error('addOption 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deletePoll({required String tripId, required String pollId}) async {
    try {
      LogService.info('刪除投票: $pollId', source: _source);
      await _pollApi.deletePoll(tripId, pollId);
    } catch (e) {
      LogService.error('deletePoll 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteOption({required String tripId, required String pollId, required String optionId}) async {
    try {
      LogService.info('刪除投票選項: $optionId', source: _source);
      await _pollApi.deleteOption(tripId, pollId, optionId);
    } catch (e) {
      LogService.error('deleteOption 失敗: $e', source: _source);
      rethrow;
    }
  }
}
