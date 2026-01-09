import '../../data/models/poll.dart';

/// 投票服務介面
/// 負責投票的建立、投票、管理
abstract interface class IPollService {
  /// 取得所有投票列表
  Future<List<Poll>> getPolls({required String userId});

  /// 建立新投票
  Future<void> createPoll({
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
  Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  });

  /// 新增選項
  Future<void> addOption({required String pollId, required String text, required String creatorId});

  /// 關閉投票
  Future<void> closePoll({required String pollId, required String userId});

  /// 刪除投票
  Future<void> deletePoll({required String pollId, required String userId});

  /// 刪除選項
  Future<void> deleteOption({required String optionId, required String userId});
}
