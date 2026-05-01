import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../entities/poll.dart';

/// 投票資料倉庫介面（支援 Offline-First）
///
/// 負責投票的本地快取與雲端操作。
abstract interface class IPollRepository {
  /// 初始化本地資料庫
  Future<Result<void, Exception>> init();

  /// 從本地取得行程投票
  ///
  /// [tripId] 行程 ID
  List<Poll> getByTripId(String tripId);

  /// 同步：從雲端拉取分頁資料並更新本地
  ///
  /// [tripId] 行程 ID
  Future<Result<PaginatedList<Poll>, Exception>> syncPolls(String tripId, {int? page, int? limit});

  /// 建立新投票（雲端）
  ///
  /// [tripId] 行程 ID
  /// [title] 投票標題
  /// [options] 初始選項列表
  /// [allowMultiple] 是否允許複選
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  });

  /// 投票（雲端）
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [optionIds] 選擇的選項 ID 列表
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  });

  /// 新增選項（雲端）
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  /// [optionText] 新選項文字
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  });

  /// 刪除投票（雲端 + 本地）
  ///
  /// [tripId] 行程 ID
  /// [pollId] 投票 ID
  Future<Result<void, Exception>> delete(String tripId, String pollId);
}
