import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../models/group_event.dart';
import '../../models/group_event_comment.dart';
import '../../api/models/group_event_api_models.dart';
import '../../api/services/group_event_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_group_event_remote_data_source.dart';

/// 揪團 (Group Event) 的遠端資料來源實作
@LazySingleton(as: IGroupEventRemoteDataSource)
class GroupEventRemoteDataSource implements IGroupEventRemoteDataSource {
  static const String _source = 'GroupEventRemoteDataSource';

  final GroupEventApiService _groupEventApi;

  GroupEventRemoteDataSource(Dio dio)
      : _groupEventApi = GroupEventApiService(dio);

  @override
  Future<List<GroupEvent>> getEvents({required String userId, String? status}) async {
    try {
      LogService.info('獲取揪團列表: $userId', source: _source);
      final events = await _groupEventApi.listEvents(status ?? 'open');
      LogService.info('已獲取 ${events.length} 個揪團', source: _source);
      return events;
    } catch (e) {
      LogService.error('getEvents 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<GroupEvent> getEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('獲取揪團詳情: $eventId', source: _source);
      return await _groupEventApi.getEvent(eventId);
    } catch (e) {
      LogService.error('getEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<String> createEvent(GroupEvent event) async {
    try {
      LogService.info('建立新揪團: ${event.title}', source: _source);
      final request = GroupEventCreateRequest(
        title: event.title,
        description: event.description,
        location: event.location,
        startDate: event.startDate,
        endDate: event.endDate,
        maxMembers: event.maxMembers,
        approvalRequired: event.approvalRequired,
        privateMessage: event.privateMessage.isNotEmpty ? event.privateMessage : null,
        linkedTripId: event.linkedTripId,
      );
      final created = await _groupEventApi.createEvent(request);
      return created.id;
    } catch (e) {
      LogService.error('createEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(GroupEvent event, String userId) async {
    try {
      LogService.info('更新揪團: ${event.id}', source: _source);
      final request = GroupEventUpdateRequest(
        title: event.title,
        description: event.description,
        location: event.location,
        startDate: event.startDate,
        endDate: event.endDate,
        maxMembers: event.maxMembers,
        approvalRequired: event.approvalRequired,
        privateMessage: event.privateMessage,
      );
      await _groupEventApi.updateEvent(event.id, request);
    } catch (e) {
      LogService.error('updateEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> closeEvent({required String eventId, required String userId, String action = 'close'}) async {
    try {
      LogService.info('結束揪團: $eventId', source: _source);
      await _groupEventApi.updateEventStatus(
        eventId,
        GroupEventStatusRequest(status: 'closed', action: action),
      );
    } catch (e) {
      LogService.error('closeEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('刪除揪團: $eventId', source: _source);
      await _groupEventApi.deleteEvent(eventId);
    } catch (e) {
      LogService.error('deleteEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<String> applyEvent({required String eventId, required String userId, String? message}) async {
    try {
      LogService.info('申請參加揪團: $eventId', source: _source);
      final result = await _groupEventApi.applyEvent(
        eventId,
        GroupEventApplyRequest(message: message),
      );
      return result.id;
    } catch (e) {
      LogService.error('applyEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> cancelApplication({required String applicationId, required String userId}) async {
    try {
      LogService.info('取消報名申請: $applicationId', source: _source);
      await _groupEventApi.cancelApplication(applicationId);
    } catch (e) {
      LogService.error('cancelApplication 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required String action,
    required String userId,
  }) async {
    try {
      LogService.info('審核申請: $applicationId ($action)', source: _source);
      await _groupEventApi.reviewApplication(
        applicationId,
        GroupEventReviewRequest(action: action),
      );
    } catch (e) {
      LogService.error('reviewApplication 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<List<GroupEventApplication>> getApplications({required String eventId, required String userId}) async {
    try {
      LogService.info('獲取揪團申請列表: $eventId', source: _source);
      return await _groupEventApi.listApplications(eventId);
    } catch (e) {
      LogService.error('getApplications 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<List<GroupEvent>> getMyEvents({required String userId, required String type}) async {
    try {
      LogService.info('獲取我的揪團: $userId, 類型: $type', source: _source);
      return await _groupEventApi.listMyEvents(type);
    } catch (e) {
      LogService.error('getMyEvents 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> likeEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('點讚揪團: $eventId', source: _source);
      await _groupEventApi.likeEvent(eventId);
    } catch (e) {
      LogService.error('likeEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> unlikeEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('取消點讚揪團: $eventId', source: _source);
      await _groupEventApi.unlikeEvent(eventId);
    } catch (e) {
      LogService.error('unlikeEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<GroupEventComment> addComment({
    required String eventId,
    required String userId,
    required String content,
  }) async {
    try {
      LogService.info('新增揪團留言: $eventId', source: _source);
      return await _groupEventApi.addComment(
        eventId,
        GroupEventCommentRequest(content: content),
      );
    } catch (e) {
      LogService.error('addComment 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<List<GroupEventComment>> getComments({required String eventId}) async {
    try {
      LogService.info('獲取揪團留言: $eventId', source: _source);
      return await _groupEventApi.listComments(eventId);
    } catch (e) {
      LogService.error('getComments 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteComment({required String commentId, required String userId}) async {
    try {
      LogService.info('刪除留言: $commentId', source: _source);
      await _groupEventApi.deleteComment(commentId);
    } catch (e) {
      LogService.error('deleteComment 失敗: $e', source: _source);
      rethrow;
    }
  }
}
