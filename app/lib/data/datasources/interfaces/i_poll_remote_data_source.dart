import '../../models/poll.dart';

/// 投票遠端資料來源介面
///
/// 負責定義與後端 API 進行投票資料交換的操作。
/// 所有方法皆需網路連線，失敗時會拋出 Exception。
abstract interface class IPollRemoteDataSource {
  /// 取得投票列表
  ///
  /// [tripId] 行程 ID
  /// 回傳: 投票列表
  /// 拋出: Exception 當 API 呼叫失敗
  Future<List<Poll>> getPolls(String tripId);

  /// 建立新投票
  ///
  /// [tripId] 行程 ID
  /// [title] 投票標題
  /// [description] 投票說明 (可選)
  /// [deadline] 截止時間 (可選)
  /// [isAllowAddOption] 是否允許參與者新增選項
  /// [maxOptionLimit] 選項數量上限
  /// [allowMultipleVotes] 是否允許複選
  /// [initialOptions] 初始選項列表
  /// 回傳: 新投票 ID
  /// 拋出: Exception 當 API 呼叫失敗
  Future<String> createPoll({
    required String tripId,
    required String title,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  });

  /// 對選項投票
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [optionId] 選擇的選項 ID
  /// 拋出: Exception 當 API 呼叫失敗
  Future<void> voteOption({required String tripId, required String pollId, required String optionId});

  /// 新增投票選項
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [text] 選項文字
  /// 拋出: Exception 當 API 呼叫失敗
  Future<void> addOption({required String tripId, required String pollId, required String text});

  /// 刪除投票
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// 拋出: Exception 當 API 呼叫失敗或無權限
  Future<void> deletePoll({required String tripId, required String pollId});

  /// 刪除選項
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [optionId] 欲刪除的選項 ID
  /// 拋出: Exception 當 API 呼叫失敗或無權限
  Future<void> deleteOption({required String tripId, required String pollId, required String optionId});
}
