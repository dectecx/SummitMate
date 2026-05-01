import '../../models/poll_model.dart';

/// 投票本地資料來源介面
///
/// 負責定義對本地資料庫 (Hive) 的 CRUD 操作。
/// 投票資料會在同步後快取至本地供離線讀取。
abstract interface class IPollLocalDataSource {
  /// 取得所有投票
  ///
  /// 回傳: 投票列表
  List<PollModel> getAllPolls();

  /// 透過 ID 取得單一投票
  ///
  /// [id] 投票 UUID
  /// 回傳: 投票物件，若不存在則回傳 null
  PollModel? getPollById(String id);

  /// 儲存投票列表 (覆寫模式)
  ///
  /// [polls] 欲儲存的投票列表，會清除現有資料後寫入
  Future<void> savePolls(List<PollModel> polls);

  /// 儲存單一投票
  ///
  /// [poll] 欲儲存的投票物件 (新增或更新)
  Future<void> savePoll(PollModel poll);

  /// 刪除投票
  ///
  /// [id] 欲刪除的投票 UUID
  Future<void> deletePoll(String id);

  /// 清除所有投票
  ///
  /// 用於登出或重置情境。
  Future<void> clear();
}
