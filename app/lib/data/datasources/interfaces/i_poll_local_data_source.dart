import '../../../domain/entities/poll.dart';

/// 投票本地資料來源介面
abstract interface class IPollLocalDataSource {
  /// 取得所有投票
  Future<List<Poll>> getAllPolls();

  /// 透過 ID 取得單一投票
  Future<Poll?> getPollById(String id);

  /// 儲存投票列表 (覆寫模式)
  Future<void> savePolls(List<Poll> polls);

  /// 儲存單一投票
  Future<void> savePoll(Poll poll);

  /// 刪除投票
  Future<void> deletePoll(String id);

  /// 清除所有投票
  Future<void> clear();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  Future<DateTime?> getLastSyncTime();
}
