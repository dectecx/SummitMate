import '../../models/poll.dart';

/// Poll Repository 抽象介面
/// 定義投票資料存取的契約
abstract interface class IPollRepository {
  /// 初始化 Box
  Future<void> init();

  /// 取得所有投票
  List<Poll> getAllPolls();

  /// 儲存所有投票 (清除舊資料並寫入新資料)
  ///
  /// [polls] 欲儲存的投票列表
  Future<void> savePolls(List<Poll> polls);

  /// 清除所有投票
  Future<void> clearAll();

  /// 儲存最後同步時間
  ///
  /// [time] 同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();
}
