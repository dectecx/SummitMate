import '../../models/poll.dart';
import '../../../core/error/result.dart';

/// 投票資料倉庫介面 (支援 Offline-First)
abstract interface class IPollRepository {
  /// 初始化本地資料庫
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得所有投票 (本地快取)
  List<Poll> getAll();

  /// 取得單一投票 (本地快取)
  Poll? getById(String id);

  /// 儲存投票列表 (本地)
  Future<void> saveAll(List<Poll> polls);

  /// 儲存單一投票 (本地)
  Future<void> save(Poll poll);

  /// 刪除投票 (本地)
  Future<void> delete(String id);

  /// 清除所有本地資料 (登出時使用)
  Future<Result<void, Exception>> clearAll();

  // ========== Sync Operations ==========

  /// 同步: 從雲端拉取最新資料並更新本地
  Future<Result<void, Exception>> sync({required String tripId});

  /// 取得上次同步時間
  DateTime? getLastSyncTime();

  // ========== Remote Write Operations ==========

  /// 建立新投票 (雲端)
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  });

  /// 投票 (雲端)
  Future<Result<void, Exception>> vote({required String tripId, required String pollId, required String optionId});

  /// 新增選項 (雲端)
  Future<Result<void, Exception>> addOption({required String tripId, required String pollId, required String text});

  /// 刪除投票 (雲端 + 本地)
  Future<Result<void, Exception>> remove({required String tripId, required String pollId});

  /// 刪除選項 (雲端)
  Future<Result<void, Exception>> removeOption({
    required String tripId,
    required String pollId,
    required String optionId,
  });
}
