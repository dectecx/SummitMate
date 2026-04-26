import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/poll.dart';

/// 投票資料倉庫介面 (支援 Offline-First)
abstract interface class IPollRepository {
  /// 初始化本地資料庫
  Future<Result<void, Exception>> init();

  /// 從本地取得行程投票
  List<Poll> getByTripId(String tripId);

  /// 同步: 從雲端拉取分頁資料並更新本地
  Future<Result<PaginatedList<Poll>, Exception>> syncPolls(String tripId, {int? page, int? limit});

  /// 建立新投票 (雲端)
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  });

  /// 投票 (雲端)
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  });

  /// 新增選項 (雲端)
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  });

  /// 刪除投票 (雲端 + 本地)
  Future<Result<void, Exception>> delete(String tripId, String pollId);
}
