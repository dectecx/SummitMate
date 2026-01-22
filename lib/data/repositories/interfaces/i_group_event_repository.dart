import '../../../core/error/result.dart';
import '../../models/group_event.dart';
import '../../models/group_event_comment.dart';

/// 揪團 Repository 抽象介面
/// 定義揪團資料存取的契約 (支援 Offline-First)
abstract interface class IGroupEventRepository {
  /// 初始化 Repository
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得所有揪團 (本地快取)
  List<GroupEvent> getAll();

  /// 取得單一揪團 (本地快取)
  GroupEvent? getById(String eventId);

  /// 儲存揪團列表到本地
  Future<void> saveAll(List<GroupEvent> events);

  /// 儲存單一揪團到本地
  Future<void> save(GroupEvent event);

  /// 從本地刪除揪團
  Future<void> delete(String eventId);

  /// 清除所有本地資料 (登出時使用)
  Future<Result<void, Exception>> clearAll();

  // ========== Application Data Operations ==========

  /// 取得所有報名紀錄 (本地快取)
  List<GroupEventApplication> getAllApplications();

  /// 儲存報名紀錄列表到本地
  Future<void> saveApplications(List<GroupEventApplication> applications);

  // ========== Sync Operations ==========

  /// 取得最後同步時間
  ///
  /// 回傳: 最後同步時間，若從未同步則回傳 null
  DateTime? getLastSyncTime();

  /// 同步所有揪團 (類別篩選)
  Future<Result<List<GroupEvent>, Exception>> syncEvents({String? category});

  /// 同步指定揪團詳細資料
  Future<Result<GroupEvent, Exception>> syncEventById(String eventId);

  /// 同步使用者報名紀錄
  Future<Result<List<GroupEventApplication>, Exception>> syncMyApplications(String userId);

  // ========== Remote Write Operations ==========

  /// 建立新揪團 (雲端)
  Future<Result<String, Exception>> create({
    required String title,
    required String description,
    required String category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
    required String creatorId,
  });

  /// 更新揪團 (雲端)
  Future<Result<void, Exception>> update(GroupEvent event);

  /// 刪除揪團 (雲端 + 本地)
  Future<Result<void, Exception>> remove({required String eventId, required String userId});

  /// 報名揪團 (雲端)
  Future<Result<void, Exception>> apply({required String eventId, required String userId, String? note});

  /// 取消報名 (雲端)
  Future<Result<void, Exception>> cancelApplication({required String eventId, required String userId});

  /// 審核報名 (雲端)
  Future<Result<void, Exception>> reviewApplication({
    required String eventId,
    required String applicantUserId,
    required String reviewerId,
    required String action,
    String? note,
  });

  /// 取得報名列表 (雲端)
  Future<Result<List<GroupEventApplication>, Exception>> getApplications({required String eventId});

  // ========== Like Operations ==========

  /// 喜歡揪團 (雲端 + 本地持久化)
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  Future<Result<void, Exception>> likeEvent({required String eventId, required String userId});

  /// 取消喜歡 (雲端 + 本地持久化)
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  Future<Result<void, Exception>> unlikeEvent({required String eventId, required String userId});

  /// 關閉揪團 (雲端)
  ///
  /// [eventId] 揪團 ID
  /// [userId] 操作者 ID
  Future<Result<void, Exception>> closeEvent({required String eventId, required String userId});

  // ========== Comment Operations ==========

  /// 取得留言列表 (雲端)
  ///
  /// [eventId] 揪團 ID
  Future<Result<List<GroupEventComment>, Exception>> getComments({required String eventId});

  /// 新增留言 (雲端)
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  /// [content] 留言內容
  Future<Result<GroupEventComment, Exception>> addComment({
    required String eventId,
    required String userId,
    required String content,
  });

  /// 刪除留言 (雲端)
  ///
  /// [commentId] 留言 ID
  /// [userId] 使用者 ID
  Future<Result<void, Exception>> deleteComment({required String commentId, required String userId});
}
