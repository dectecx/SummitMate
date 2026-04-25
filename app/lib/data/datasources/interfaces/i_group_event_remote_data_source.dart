import '../../../core/models/paginated_list.dart';
import '../../models/group_event.dart';
import '../../models/group_event_comment.dart';
import '../../../core/error/result.dart';

/// 揪團 (Group Event) 的遠端資料來源介面
abstract interface class IGroupEventRemoteDataSource {
  /// 獲取揪團列表 (支援分頁與過濾)
  Future<Result<PaginatedList<GroupEvent>, Exception>> getEvents({
    int? page,
    int? limit,
    String? status,
    String? category,
  });

  /// 獲取單一揪團詳情
  Future<Result<GroupEvent, Exception>> getEventById(String eventId);

  /// 建立揪團
  Future<Result<String, Exception>> createEvent({
    required String title,
    required String description,
    required String category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
  });

  /// 刪除揪團
  Future<Result<void, Exception>> deleteEvent(String eventId);

  /// 申請參加揪團
  Future<Result<String, Exception>> applyEvent({
    required String eventId,
    String? note,
  });

  /// 取消申請
  Future<Result<void, Exception>> cancelApplication(String eventId);

  /// 獲取我申請的揪團清單
  Future<Result<List<GroupEventApplication>, Exception>> getMyApplications();

  /// 獲取揪團的所有申請 (僅限建立者)
  Future<Result<List<GroupEventApplication>, Exception>> getEventApplications(String eventId);

  /// 審核申請 (僅限建立者)
  Future<Result<void, Exception>> reviewApplication({
    required String eventId,
    required String applicantUserId,
    required String action,
    String? note,
  });

  /// 結案/關閉揪團 (僅限建立者)
  Future<Result<void, Exception>> closeEvent(String eventId);

  /// 點讚/取消點讚
  Future<Result<void, Exception>> likeEvent(String eventId);
  Future<Result<void, Exception>> unlikeEvent(String eventId);

  /// 留言相關
  Future<Result<List<GroupEventComment>, Exception>> getComments(String eventId);
  Future<Result<GroupEventComment, Exception>> addComment({
    required String eventId,
    required String content,
  });
  Future<Result<void, Exception>> deleteComment(String commentId);
}
