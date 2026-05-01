import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';
import '../../api/mappers/group_event_api_mapper.dart';
import '../../api/services/group_event_api_service.dart';
import '../../api/models/group_event_api_models.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_group_event_remote_data_source.dart';
import '../../../core/error/result.dart';
/// 揪團 (Group Event) 的遠端資料來源實作
@LazySingleton(as: IGroupEventRemoteDataSource)
class GroupEventRemoteDataSource implements IGroupEventRemoteDataSource {
  static const String _source = 'GroupEventRemoteDataSource';

  final GroupEventApiService _groupEventApi;

  GroupEventRemoteDataSource(this._groupEventApi);

  @override
  Future<Result<PaginatedList<GroupEvent>, Exception>> getEvents({
    int? page,
    int? limit,
    String? status,
    GroupEventCategory? category,
  }) async {
    try {
      LogService.info('獲取揪團列表 (page: $page, limit: $limit, category: $category)...', source: _source);
      final response = await _groupEventApi.listEvents(
        page: page,
        limit: limit,
        status: status,
        category: category?.value,
      );

      final items = response.items.map(GroupEventApiMapper.fromResponse).toList();

      return Success(
        PaginatedList<GroupEvent>(
          items: items,
          page: response.pagination.page,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ),
      );
    } catch (e) {
      LogService.error('獲取揪團失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<GroupEvent, Exception>> getEventById(String eventId) async {
    try {
      final response = await _groupEventApi.getEvent(eventId);
      return Success(GroupEventApiMapper.fromResponse(response));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> createEvent({
    required String title,
    required String description,
    required GroupEventCategory category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
    String? linkedTripId,
  }) async {
    try {
      final request = GroupEventCreateRequest(
        title: title,
        description: description,
        category: category,
        location: eventLocation,
        startDate: eventDate,
        maxMembers: maxParticipants,
        approvalRequired: true, // Default to true if not specified
        linkedTripId: linkedTripId,
      );
      final response = await _groupEventApi.createEvent(request);
      return Success(response.id);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteEvent(String eventId) async {
    try {
      await _groupEventApi.deleteEvent(eventId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> applyEvent({required String eventId, String? note}) async {
    try {
      final response = await _groupEventApi.applyEvent(eventId, GroupEventApplyRequest(message: note));
      return Success(response.id);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> cancelApplication(String applicationId) async {
    try {
      await _groupEventApi.cancelApplication(applicationId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<List<GroupEventApplication>, Exception>> getMyApplications() async {
    try {
      await _groupEventApi.listMyEvents('applied');
      // The API returns List<GroupEventResponse> for listMyEvents.
      // But the interface expects List<GroupEventApplication>.
      // This is a conceptual mismatch in the interface vs API.
      // For now, return empty or throw if not possible.
      throw UnimplementedError('getMyApplications concept mismatch in API (returns events, not applications)');
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<List<GroupEventApplication>, Exception>> getEventApplications(String eventId) async {
    try {
      final response = await _groupEventApi.listApplications(eventId);
      return Success(response.map(GroupEventApiMapper.fromApplicationResponse).toList());
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> reviewApplication({
    required String eventId,
    required String applicantUserId,
    required String action,
    String? note,
  }) async {
    try {
      // action maps to 'approve', 'reject', etc.
      await _groupEventApi.reviewApplication(applicantUserId, GroupEventReviewRequest(action: action));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> closeEvent(String eventId) async {
    try {
      await _groupEventApi.updateEventStatus(eventId, const GroupEventStatusRequest(status: 'closed', action: 'close'));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> likeEvent(String eventId) async {
    try {
      await _groupEventApi.likeEvent(eventId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> unlikeEvent(String eventId) async {
    try {
      await _groupEventApi.unlikeEvent(eventId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<List<GroupEventComment>, Exception>> getComments(String eventId) async {
    try {
      final response = await _groupEventApi.listComments(eventId);
      return Success(response.map(GroupEventApiMapper.fromCommentResponse).toList());
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<GroupEventComment, Exception>> addComment({required String eventId, required String content}) async {
    try {
      final response = await _groupEventApi.addComment(eventId, GroupEventCommentRequest(content: content));
      return Success(GroupEventApiMapper.fromCommentResponse(response));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteComment(String commentId) async {
    try {
      await _groupEventApi.deleteComment(commentId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateLinkedTrip({required String eventId, String? linkedTripId}) async {
    try {
      await _groupEventApi.updateTripLink(eventId, GroupEventTripLinkRequest(linkedTripId: linkedTripId));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<GroupEvent, Exception>> updateTripSnapshot(String eventId) async {
    try {
      final response = await _groupEventApi.updateTripSnapshot(eventId);
      return Success(GroupEventApiMapper.fromResponse(response));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
