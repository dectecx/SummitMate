import '../../../core/models/paginated_list.dart';
import '../../models/poll.dart';
import '../../../core/error/result.dart';

/// 投票 (Polls) 的遠端資料來源介面
abstract interface class IPollRemoteDataSource {
  /// 獲取行程投票列表 (支援分頁)
  Future<Result<PaginatedList<Poll>, Exception>> getPolls(String tripId, {int? page, int? limit});

  /// 建立新投票
  ///
  /// [tripId] 行程 ID
  /// [title] 投票標題
  /// [options] 初始選項列表
  /// [allowMultiple] 是否允許複選
  /// 回傳: 新投票 ID
  Future<Result<String, Exception>> createPoll({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  });

  /// 刪除投票
  Future<Result<void, Exception>> deletePoll(String tripId, String pollId);

  /// 投票操作
  Future<Result<void, Exception>> vote(String tripId, String pollId, List<String> optionIds);

  /// 新增選項
  Future<Result<void, Exception>> addOption(String tripId, String pollId, String optionText);
}
