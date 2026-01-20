import '../clients/network_aware_client.dart';
import '../clients/gas_api_client.dart';
import '../../core/di.dart';
import '../../core/constants.dart';
import '../../data/models/group_event.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_group_event_service.dart';
import '../../core/error/result.dart';
import '../../data/datasources/interfaces/i_group_event_remote_data_source.dart';

/// 揪團服務
///
/// 負責與後端 (GAS) 溝通以管理揪團功能：
/// - 取得揪團列表
/// - 取得揪團詳情
/// - 建立/更新/刪除揪團
/// - 報名/取消報名/審核報名
/// - 我的揪團
class GroupEventService implements IGroupEventService {
  static const String _source = 'GroupEventService';

  final NetworkAwareClient _apiClient;
  final IGroupEventRemoteDataSource _remoteDataSource;

  GroupEventService({
    NetworkAwareClient? apiClient,
    IGroupEventRemoteDataSource? remoteDataSource,
  }) : _apiClient = apiClient ?? getIt<NetworkAwareClient>(),
       _remoteDataSource = remoteDataSource ?? getIt<IGroupEventRemoteDataSource>();

  /// 取得揪團列表
  @override
  Future<Result<List<GroupEvent>, Exception>> getEvents({
    String? filter,
    String? status,
    required String userId,
  }) async {
    try {
      LogService.info('Fetching group events for user: $userId', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventList,
        'user_id': userId,
        'filter': filter,
        'status': status ?? 'open',
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          final List<dynamic> eventsJson = gasResponse.data['events'] ?? [];
          LogService.info('Fetched ${eventsJson.length} group events', source: _source);
          return Success(eventsJson.map((e) => GroupEvent.fromJson(e)).toList());
        } else {
          LogService.error('Fetch events failed: [${gasResponse.code}] ${gasResponse.message}', source: _source);
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error fetching events: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取得揪團詳情
  @override
  Future<Result<GroupEvent, Exception>> getEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('Fetching event detail: $eventId', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventGet,
        'event_id': eventId,
        'user_id': userId,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return Success(GroupEvent.fromJson(gasResponse.data['event']));
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error fetching event detail: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 建立揪團
  @override
  Future<Result<String, Exception>> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    int maxMembers = 10,
    bool approvalRequired = false,
    String? privateMessage,
    required String creatorId,
  }) async {
    try {
      LogService.info('Creating group event: $title', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventCreate,
        'title': title,
        'description': description ?? '',
        'location': location ?? '',
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'max_members': maxMembers,
        'approval_required': approvalRequired,
        'private_message': privateMessage ?? '',
        'creator_id': creatorId,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          final id = gasResponse.data['id'] as String;
          LogService.info('Event created: $id', source: _source);
          return Success(id);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error creating event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 更新揪團
  @override
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
  }) async {
    try {
      LogService.info('Updating event: $eventId', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventUpdate,
        'event_id': eventId,
        'user_id': userId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (maxMembers != null) 'max_members': maxMembers,
        if (approvalRequired != null) 'approval_required': approvalRequired,
        if (privateMessage != null) 'private_message': privateMessage,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return const Success(null);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error updating event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 關閉/取消揪團
  @override
  Future<Result<void, Exception>> closeEvent({
    required String eventId,
    required String userId,
    String action = 'close',
  }) async {
    try {
      LogService.info('Closing event: $eventId (action: $action)', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventClose,
        'event_id': eventId,
        'user_id': userId,
        'close_action': action,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return const Success(null);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error closing event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 刪除揪團
  @override
  Future<Result<void, Exception>> deleteEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('Deleting event: $eventId', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventDelete,
        'event_id': eventId,
        'user_id': userId,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return const Success(null);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error deleting event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 報名揪團
  @override
  Future<Result<String, Exception>> applyEvent({
    required String eventId,
    required String userId,
    String? message,
  }) async {
    try {
      LogService.info('Applying for event: $eventId by user: $userId', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventApply,
        'event_id': eventId,
        'user_id': userId,
        'message': message ?? '',
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          final appId = gasResponse.data['id'] as String;
          LogService.info('Applied for event: $eventId, id: $appId', source: _source);
          return Success(appId);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error applying for event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取消報名
  @override
  Future<Result<void, Exception>> cancelApplication({required String applicationId, required String userId}) async {
    try {
      LogService.info('Cancelling application: $applicationId', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventCancelApplication,
        'application_id': applicationId,
        'user_id': userId,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return const Success(null);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error cancelling application: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 審核報名
  @override
  Future<Result<void, Exception>> reviewApplication({
    required String applicationId,
    required String action,
    required String userId,
  }) async {
    try {
      LogService.info('Reviewing application: $applicationId (action: $action)', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionGroupEventReviewApplication,
        'application_id': applicationId,
        'review_action': action,
        'user_id': userId,
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return const Success(null);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error reviewing application: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 我的揪團
  @override
  Future<Result<List<GroupEvent>, Exception>> getMyEvents({required String userId, required String type}) async {
    try {
      LogService.info('Fetching my events for user: $userId, type: $type', source: _source);
      final response = await _apiClient.post({'action': ApiConfig.actionGroupEventMy, 'user_id': userId, 'type': type});

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          final List<dynamic> eventsJson = gasResponse.data['events'] ?? [];
          return Success(eventsJson.map((e) => GroupEvent.fromJson(e)).toList());
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('Error fetching my events: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 喜歡揪團
  ///
  /// 委派呼叫 [IGroupEventRemoteDataSource.likeEvent]
  @override
  Future<Result<void, Exception>> likeEvent({required String eventId, required String userId}) async {
    try {
      await _remoteDataSource.likeEvent(eventId: eventId, userId: userId);
      return const Success(null);
    } catch (e) {
      LogService.error('Error liking event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取消喜歡
  ///
  /// 委派呼叫 [IGroupEventRemoteDataSource.unlikeEvent]
  @override
  Future<Result<void, Exception>> unlikeEvent({required String eventId, required String userId}) async {
    try {
      await _remoteDataSource.unlikeEvent(eventId: eventId, userId: userId);
      return const Success(null);
    } catch (e) {
      LogService.error('Error unliking event: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
