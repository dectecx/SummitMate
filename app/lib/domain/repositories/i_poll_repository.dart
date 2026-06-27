import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../entities/poll.dart';

/// 投票資料倉庫介面（B 模式：讀快取／寫線上）
///
/// UI／Cubit 一律只透過本介面存取投票資料：
/// - 讀取（[getByTripId]）回傳本地快取。
/// - [refresh] 與所有寫入（[create]/[vote]/[addOption]/[delete]）為線上限定，
///   離線時回傳 `OfflineException`；成功後同步更新本地快取。
abstract interface class IPollRepository {
  /// 初始化本地資料庫
  Future<Result<void, Exception>> init();

  /// 從本地快取取得行程投票
  Future<List<Poll>> getByTripId(String tripId);

  /// 線上拉取最新投票並更新本地快取
  Future<Result<PaginatedList<Poll>, Exception>> refresh(String tripId, {int? page, int? limit});

  /// 建立投票（線上限定）。回傳新投票 ID。
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  });

  /// 投票（線上限定）
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  });

  /// 新增選項（線上限定）
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  });

  /// 刪除投票（線上限定）
  Future<Result<void, Exception>> delete(String tripId, String pollId);
}
