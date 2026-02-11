import '../../data/models/poll.dart';
import '../../core/error/result.dart';

/// 投票服務介面
/// 負責投票的建立、投票、管理
abstract interface class IPollService {
  /// 取得所有投票列表
  ///
  /// [userId] 目前使用者 ID (用於判斷是否已投票)
  Future<Result<List<Poll>, Exception>> getPolls({required String userId});

  /// 建立新投票
  ///
  /// [title] 投票標題
  /// [description] 描述
  /// [creatorId] 建立者 ID
  /// [deadline] 截止時間 (可選)
  /// [isAllowAddOption] 是否允許其他人新增選項
  /// [maxOptionLimit] 最大選項數限制
  /// [allowMultipleVotes] 是否允許複選
  /// [initialOptions] 初始選項列表
  Future<Result<void, Exception>> createPoll({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  });

  /// 對選項投票
  ///
  /// [pollId] 投票 ID
  /// [optionIds] 選取的所有選項 ID 列表
  /// [userId] 投票者 ID
  /// [userName] 投票者名稱 (可選)
  Future<Result<void, Exception>> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  });

  /// 新增選項
  ///
  /// [pollId] 投票 ID
  /// [text] 選項文字
  /// [creatorId] 建立者 ID
  Future<Result<void, Exception>> addOption({required String pollId, required String text, required String creatorId});

  /// 關閉投票
  ///
  /// [pollId] 投票 ID
  /// [userId] 操作者 ID (必須是建立者)
  Future<Result<void, Exception>> closePoll({required String pollId, required String userId});

  /// 刪除投票
  ///
  /// [pollId] 投票 ID
  /// [userId] 操作者 ID (必須是建立者)
  Future<Result<void, Exception>> deletePoll({required String pollId, required String userId});

  /// 刪除選項
  ///
  /// [optionId] 選項 ID
  /// [userId] 操作者 ID (必須是建立者或選項建立者)
  Future<Result<void, Exception>> deleteOption({required String optionId, required String userId});
}
