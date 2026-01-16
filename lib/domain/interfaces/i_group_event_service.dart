import '../../core/error/result.dart';
import '../../data/models/group_event.dart';

/// 揪團服務介面
abstract class IGroupEventService {
  /// 取得揪團列表
  Future<Result<List<GroupEvent>, Exception>> getEvents({
    required String userId,
    String? filter,
    String? status,
  });

  /// 取得揪團詳情
  Future<Result<GroupEvent, Exception>> getEvent({
    required String eventId,
    required String userId,
  });

  /// 建立揪團
  Future<Result<String, Exception>> createEvent({
    required String creatorId,
    required String title,
    String description,
    String location,
    required DateTime startDate,
    DateTime? endDate,
    required int maxMembers,
    bool approvalRequired,
    String privateMessage,
  });

  /// 更新揪團
  Future<Result<void, Exception>> updateEvent({
    required String eventId,
    required String userId,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxMembers,
    bool? approvalRequired,
    String? privateMessage,
  });

  /// 關閉揪團
  Future<Result<void, Exception>> closeEvent({
    required String eventId,
    required String userId,
  });

  /// 刪除揪團
  Future<Result<void, Exception>> deleteEvent({
    required String eventId,
    required String userId,
  });

  /// 報名揪團 (returns application ID)
  Future<Result<String, Exception>> applyEvent({
    required String eventId,
    required String userId,
    String? message,
  });

  /// 取消報名
  Future<Result<void, Exception>> cancelApplication({
    required String applicationId,
    required String userId,
  });

  /// 審核報名 (approve / reject)
  Future<Result<void, Exception>> reviewApplication({
    required String applicationId,
    required String action,
    required String userId,
  });

  /// 取得我的揪團 (created / applied / liked)
  Future<Result<List<GroupEvent>, Exception>> getMyEvents({
    required String userId,
    required String type,
  });

  /// 喜歡揪團 (TODO)
  Future<Result<void, Exception>> likeEvent({
    required String eventId,
    required String userId,
  });

  /// 取消喜歡 (TODO)
  Future<Result<void, Exception>> unlikeEvent({
    required String eventId,
    required String userId,
  });
}
