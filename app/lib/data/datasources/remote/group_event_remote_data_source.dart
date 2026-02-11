import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/clients/gas_api_client.dart';
import '../../../core/di.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../models/group_event.dart';
import '../../models/group_event_comment.dart';
import '../interfaces/i_group_event_remote_data_source.dart';

/// 揪團遠端資料來源實作 (GAS API)
class GroupEventRemoteDataSource implements IGroupEventRemoteDataSource {
  static const String _source = 'GroupEventRemoteDataSource';

  final NetworkAwareClient _apiClient;

  GroupEventRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  @override
  Future<List<GroupEvent>> getEvents({required String userId, String? status}) async {
    LogService.info('Fetching group events for user: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventList, 'user_id': userId, 'status': status ?? 'open'},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    final List<dynamic> eventsJson = gasResponse.data['events'] ?? [];
    LogService.info('Fetched ${eventsJson.length} group events', source: _source);
    return eventsJson.map((e) => GroupEvent.fromJson(e)).toList();
  }

  @override
  Future<GroupEvent> getEvent({required String eventId, required String userId}) async {
    LogService.info('Fetching event detail: $eventId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventGet, 'event_id': eventId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    return GroupEvent.fromJson(gasResponse.data['event']);
  }

  @override
  Future<String> createEvent(GroupEvent event) async {
    LogService.info('Creating group event: ${event.title}', source: _source);
    final response = await _apiClient.post(
      '',
      data: {
        'action': ApiConfig.actionGroupEventCreate,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'start_date': event.startDate.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'max_members': event.maxMembers,
        'approval_required': event.approvalRequired,
        'private_message': event.privateMessage,
        'creator_id': event.creatorId,
      },
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    return gasResponse.data['id'] as String;
  }

  @override
  Future<void> updateEvent(GroupEvent event, String userId) async {
    LogService.info('Updating event: ${event.id}', source: _source);
    final response = await _apiClient.post(
      '',
      data: {
        'action': ApiConfig.actionGroupEventUpdate,
        'event_id': event.id,
        'user_id': userId,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'start_date': event.startDate.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'max_members': event.maxMembers,
        'approval_required': event.approvalRequired,
        'private_message': event.privateMessage,
      },
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> closeEvent({required String eventId, required String userId, String action = 'close'}) async {
    LogService.info('Closing event: $eventId (action: $action)', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventClose, 'event_id': eventId, 'user_id': userId, 'close_action': action},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> deleteEvent({required String eventId, required String userId}) async {
    LogService.info('Deleting event: $eventId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventDelete, 'event_id': eventId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<String> applyEvent({required String eventId, required String userId, String? message}) async {
    LogService.info('Applying for event: $eventId by user: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {
        'action': ApiConfig.actionGroupEventApply,
        'event_id': eventId,
        'user_id': userId,
        'message': message ?? '',
      },
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    return gasResponse.data['id'] as String;
  }

  @override
  Future<void> cancelApplication({required String applicationId, required String userId}) async {
    LogService.info('Cancelling application: $applicationId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventCancelApplication, 'application_id': applicationId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required String action,
    required String userId,
  }) async {
    LogService.info('Reviewing application: $applicationId (action: $action)', source: _source);
    final response = await _apiClient.post(
      '',
      data: {
        'action': ApiConfig.actionGroupEventReviewApplication,
        'application_id': applicationId,
        'review_action': action,
        'user_id': userId,
      },
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<List<GroupEventApplication>> getApplications({required String eventId, required String userId}) async {
    LogService.info('Fetching applications for event: $eventId by creator: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventGetApplications, 'event_id': eventId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    final List<dynamic> appsJson = gasResponse.data['applications'] ?? [];
    return appsJson.map((a) => GroupEventApplication.fromJson(a as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<GroupEvent>> getMyEvents({required String userId, required String type}) async {
    LogService.info('Fetching my events for user: $userId, type: $type', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventMy, 'user_id': userId, 'type': type},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    final List<dynamic> eventsJson = gasResponse.data['events'] ?? [];
    return eventsJson.map((e) => GroupEvent.fromJson(e)).toList();
  }

  @override
  Future<void> likeEvent({required String eventId, required String userId}) async {
    LogService.info('Liking event: $eventId by user: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventLike, 'event_id': eventId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<void> unlikeEvent({required String eventId, required String userId}) async {
    LogService.info('Unliking event: $eventId by user: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventUnlike, 'event_id': eventId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }

  @override
  Future<GroupEventComment> addComment({
    required String eventId,
    required String userId,
    required String content,
  }) async {
    LogService.info('Adding comment to event: $eventId by user: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {
        'action': ApiConfig.actionGroupEventAddComment,
        'event_id': eventId,
        'user_id': userId,
        'content': content,
      },
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    return GroupEventComment.fromJson(gasResponse.data['comment'] as Map<String, dynamic>);
  }

  @override
  Future<List<GroupEventComment>> getComments({required String eventId}) async {
    LogService.info('Fetching comments for event: $eventId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventGetComments, 'event_id': eventId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

    final List<dynamic> commentsJson = gasResponse.data['comments'] ?? [];
    return commentsJson.map((c) => GroupEventComment.fromJson(c as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteComment({required String commentId, required String userId}) async {
    LogService.info('Deleting comment: $commentId by user: $userId', source: _source);
    final response = await _apiClient.post(
      '',
      data: {'action': ApiConfig.actionGroupEventDeleteComment, 'comment_id': commentId, 'user_id': userId},
    );

    final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
    if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
  }
}
