import '../../models/poll.dart';

/// 投票遠端資料來源介面
///
/// 負責定義與後端 API (GAS) 進行投票資料交換的操作。
/// 所有方法皆需網路連線，失敗時會拋出 Exception。
abstract class IPollRemoteDataSource {
  /// 取得投票列表
  ///
  /// [userId] 目前登入使用者 ID，用於識別投票權限
  /// 回傳: 投票列表
  /// 拋出: Exception 當 API 呼叫失敗
  Future<List<Poll>> getPolls({required String userId});

  /// 建立新投票
  ///
  /// [title] 投票標題
  /// [description] 投票說明 (可選)
  /// [creatorId] 發起者 ID
  /// [deadline] 截止時間 (可選)
  /// [isAllowAddOption] 是否允許參與者新增選項
  /// [maxOptionLimit] 選項數量上限
  /// [allowMultipleVotes] 是否允許複選
  /// [initialOptions] 初始選項列表
  /// 回傳: 新投票 ID
  /// 拋出: Exception 當 API 呼叫失敗
  Future<String> createPoll({
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
  /// [optionIds] 選擇的選項 ID 列表 (複選時可多個)
  /// [userId] 投票者 ID
  /// [userName] 投票者名稱 (顯示用)
  /// 拋出: Exception 當 API 呼叫失敗
  Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  });

  /// 新增選項
  ///
  /// [pollId] 投票 ID
  /// [text] 選項文字
  /// [creatorId] 新增者 ID
  /// 拋出: Exception 當 API 呼叫失敗或不允許新增選項
  Future<void> addOption({required String pollId, required String text, required String creatorId});

  /// 關閉投票
  ///
  /// [pollId] 投票 ID
  /// [userId] 操作者 ID (需為發起者)
  /// 拋出: Exception 當 API 呼叫失敗或無權限
  Future<void> closePoll({required String pollId, required String userId});

  /// 刪除投票
  ///
  /// [pollId] 投票 ID
  /// [userId] 操作者 ID (需為發起者)
  /// 拋出: Exception 當 API 呼叫失敗或無權限
  Future<void> deletePoll({required String pollId, required String userId});

  /// 刪除選項
  ///
  /// [optionId] 選項 ID
  /// [userId] 操作者 ID (需為選項建立者或投票發起者)
  /// 拋出: Exception 當 API 呼叫失敗或無權限
  Future<void> deleteOption({required String optionId, required String userId});
}
