import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/poll.dart';
import '../../api/mappers/poll_api_mapper.dart';
import '../../api/services/poll_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_poll_remote_data_source.dart';
import '../../../core/error/result.dart';

/// 投票 (Poll) 的遠端資料來源實作
@LazySingleton(as: IPollRemoteDataSource)
class PollRemoteDataSource implements IPollRemoteDataSource {
  static const String _source = 'PollRemoteDataSource';

  final PollApiService _pollApi;

  PollRemoteDataSource(this._pollApi);

  @override
  Future<Result<PaginatedList<Poll>, Exception>> getPolls(String tripId, {int? page, int? limit}) async {
    try {
      LogService.info('獲取行程投票列表: $tripId (page: $page, limit: $limit)...', source: _source);
      final response = await _pollApi.listTripPolls(tripId, page: page, limit: limit);
      final polls = response.items.map((p) => PollApiMapper.fromResponse(p, tripId: tripId)).toList();
      return Success(PaginatedList<Poll>(
        items: polls,
        page: response.pagination.page,
        total: response.pagination.total,
        hasMore: response.pagination.hasMore,
      ));
    } catch (e) {
      LogService.error('獲取投票失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> createPoll({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  }) async {
    try {
      LogService.info('建立行程投票: $tripId - $title', source: _source);
      final request = PollApiMapper.toCreateRequest(
        title: title,
        options: options,
        allowMultiple: allowMultiple,
      );
      final response = await _pollApi.createPoll(tripId, request);
      return Success(response.id);
    } catch (e) {
      LogService.error('建立投票失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> vote(String tripId, String pollId, List<String> optionIds) async {
    try {
      LogService.info('投票: trip $tripId, poll $pollId, options $optionIds', source: _source);
      // For now, assuming backend voteOption takes one at a time or we loop
      for (final optionId in optionIds) {
        await _pollApi.voteOption(tripId, pollId, optionId);
      }
      return const Success(null);
    } catch (e) {
      LogService.error('投票失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> addOption(String tripId, String pollId, String optionText) async {
    try {
      LogService.info('新增投票選項: trip $tripId, poll $pollId, text $optionText', source: _source);
      final request = PollApiMapper.toOptionRequest(optionText);
      await _pollApi.addOption(tripId, pollId, request);
      return const Success(null);
    } catch (e) {
      LogService.error('新增選項失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deletePoll(String tripId, String pollId) async {
    try {
      LogService.info('刪除投票: trip $tripId, poll $pollId', source: _source);
      await _pollApi.deletePoll(tripId, pollId);
      return const Success(null);
    } catch (e) {
      LogService.error('刪除投票失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
