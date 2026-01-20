import '../../models/group_event.dart';
import '../../models/group_event_comment.dart';

/// 揪團 (GroupEvent) 的遠端資料來源介面
///
/// 負責定義與後端 API (GAS) 進行揪團資料交換的操作。
abstract class IGroupEventRemoteDataSource {
  /// 取得揪團列表
  ///
  /// [userId] 目前登入使用者 ID (用於計算 my_application_status)
  /// [status] 篩選條件 (open, closed, all)
  Future<List<GroupEvent>> getEvents({required String userId, String? status});

  /// 取得揪團詳情
  ///
  /// [eventId] 揪團 ID
  /// [userId] 目前登入使用者 ID
  Future<GroupEvent> getEvent({required String eventId, required String userId});

  /// 建立揪團
  ///
  /// [event] 揪團資料
  /// 回傳: 新揪團 ID
  Future<String> createEvent(GroupEvent event);

  /// 更新揪團
  ///
  /// [event] 更新後的揪團資料
  Future<void> updateEvent(GroupEvent event, String userId);

  /// 關閉/取消揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 操作者 ID
  /// [action] close 或 cancel
  Future<void> closeEvent({required String eventId, required String userId, String action = 'close'});

  /// 刪除揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 操作者 ID
  Future<void> deleteEvent({required String eventId, required String userId});

  /// 報名揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 報名者 ID
  /// [message] 報名訊息
  /// 回傳: 報名紀錄 ID
  Future<String> applyEvent({required String eventId, required String userId, String? message});

  /// 取消報名
  ///
  /// [applicationId] 報名紀錄 ID
  /// [userId] 操作者 ID
  Future<void> cancelApplication({required String applicationId, required String userId});

  /// 審核報名
  ///
  /// [applicationId] 報名紀錄 ID
  /// [action] approve 或 reject
  /// [userId] 審核者 ID
  Future<void> reviewApplication({required String applicationId, required String action, required String userId});

  /// 取得我的揪團
  ///
  /// [userId] 使用者 ID
  /// [type] created, applied, liked
  Future<List<GroupEvent>> getMyEvents({required String userId, required String type});

  /// 喜歡揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  Future<void> likeEvent({required String eventId, required String userId});

  /// 取消喜歡
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  Future<void> unlikeEvent({required String eventId, required String userId});

  /// 新增留言
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  /// [content] 留言內容
  Future<GroupEventComment> addComment({required String eventId, required String userId, required String content});

  /// 取得留言列表
  ///
  /// [eventId] 揪團 ID
  Future<List<GroupEventComment>> getComments({required String eventId});

  /// 刪除留言
  ///
  /// [commentId] 留言 ID
  /// [userId] 使用者 ID
  Future<void> deleteComment({required String commentId, required String userId});
}
