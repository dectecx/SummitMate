import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../core/di.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../models/group_event.dart';
import '../../models/group_event_comment.dart';
import '../interfaces/i_group_event_remote_data_source.dart';

/// 揪團 (Group Event) 的遠端資料來源實作
class GroupEventRemoteDataSource implements IGroupEventRemoteDataSource {
  static const String _source = 'GroupEventRemoteDataSource';

  final NetworkAwareClient _apiClient;

  GroupEventRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得揪團列表
  ///
  /// [userId] 目前登入使用者 ID
  /// [status] 狀態篩選 (如 'open', 'closed')，預設為 'open'
  @override
  Future<List<GroupEvent>> getEvents({required String userId, String? status}) async {
    try {
      LogService.info('獲取使用者揪團列表: $userId', source: _source);

      final response = await _apiClient.get('/group-events', queryParameters: {'status': status ?? 'open'});

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> eventsJson = response.data as List<dynamic>;
      LogService.info('已獲取 ${eventsJson.length} 個揪團', source: _source);
      return eventsJson.map((e) => GroupEvent.fromJson(e)).toList();
    } catch (e) {
      LogService.error('getEvents 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 取得特定揪團詳情
  ///
  /// [eventId] 揪團 ID
  /// [userId] 目前登入使用者 ID (用於檢查申請狀態)
  @override
  Future<GroupEvent> getEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('獲取揪團詳情: $eventId', source: _source);

      final response = await _apiClient.get('/group-events/$eventId');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      return GroupEvent.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      LogService.error('getEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 建立新揪團
  ///
  /// [event] 揪團資料模型
  @override
  Future<String> createEvent(GroupEvent event) async {
    try {
      LogService.info('建立新揪團: ${event.title}', source: _source);

      final response = await _apiClient.post('/group-events', data: event.toJson());

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      return response.data['id'] as String;
    } catch (e) {
      LogService.error('createEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 更新揪團資料
  ///
  /// [event] 揪團資料模型
  /// [userId] 目前登入使用者 ID (需為發起者)
  @override
  Future<void> updateEvent(GroupEvent event, String userId) async {
    try {
      LogService.info('更新揪團: ${event.id}', source: _source);

      final response = await _apiClient.put('/group-events/${event.id}', data: event.toJson());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('updateEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 結束揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 目前登入使用者 ID
  /// [action] 結束動作 (預設為 'close')
  @override
  Future<void> closeEvent({required String eventId, required String userId, String action = 'close'}) async {
    try {
      LogService.info('結束揪團: $eventId (動作: $action)', source: _source);

      final response = await _apiClient.put(
        '/group-events/$eventId/status',
        data: {'status': 'closed', 'action': action},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('closeEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 目前登入使用者 ID
  @override
  Future<void> deleteEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('刪除揪團: $eventId', source: _source);

      final response = await _apiClient.delete('/group-events/$eventId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deleteEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 申請參加揪團
  ///
  /// [eventId] 揪團 ID
  /// [userId] 目前登入使用者 ID
  /// [message] 申請訊息 (可選)
  @override
  Future<String> applyEvent({required String eventId, required String userId, String? message}) async {
    try {
      LogService.info('申請參加揪團: $eventId, 使用者: $userId', source: _source);

      final response = await _apiClient.post('/group-events/$eventId/apply', data: {'message': message ?? ''});

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      return response.data['id'] as String;
    } catch (e) {
      LogService.error('applyEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 取消報名申請
  ///
  /// [applicationId] 申請單 ID
  /// [userId] 目前登入使用者 ID
  @override
  Future<void> cancelApplication({required String applicationId, required String userId}) async {
    try {
      LogService.info('取消報名申請: $applicationId', source: _source);

      final response = await _apiClient.delete('/group-events/applications/$applicationId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('cancelApplication 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 審核報名申請
  ///
  /// [applicationId] 申請單 ID
  /// [action] 審核動作 (如 'approve', 'reject')
  /// [userId] 目前登入使用者 ID (需為揪團發起者)
  @override
  Future<void> reviewApplication({
    required String applicationId,
    required String action,
    required String userId,
  }) async {
    try {
      LogService.info('審核報名申請: $applicationId (動作: $action)', source: _source);

      final response = await _apiClient.put('/group-events/applications/$applicationId', data: {'action': action});

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('reviewApplication 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 取得所有申請人清單
  ///
  /// [eventId] 揪團 ID
  /// [userId] 目前登入使用者 ID
  @override
  Future<List<GroupEventApplication>> getApplications({required String eventId, required String userId}) async {
    try {
      LogService.info('獲取揪團申請列表: $eventId', source: _source);

      final response = await _apiClient.get('/group-events/$eventId/applications');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> appsJson = response.data as List<dynamic>;
      return appsJson.map((a) => GroupEventApplication.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      LogService.error('getApplications 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 取得「我的揪團」列表
  ///
  /// [userId] 使用者 ID
  /// [type] 列表類型 ('created' 或 'joined')
  @override
  Future<List<GroupEvent>> getMyEvents({required String userId, required String type}) async {
    try {
      LogService.info('獲取我的揪團: $userId, 類型: $type', source: _source);

      final response = await _apiClient.get('/group-events/my', queryParameters: {'type': type});

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> eventsJson = response.data as List<dynamic>;
      return eventsJson.map((e) => GroupEvent.fromJson(e)).toList();
    } catch (e) {
      LogService.error('getMyEvents 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 加入我的最愛 (按讚)
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  @override
  Future<void> likeEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('點讚揪團: $eventId', source: _source);

      final response = await _apiClient.post('/group-events/$eventId/like');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('likeEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 取消我的最愛 (收回讚)
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  @override
  Future<void> unlikeEvent({required String eventId, required String userId}) async {
    try {
      LogService.info('取消點讚揪團: $eventId', source: _source);

      final response = await _apiClient.delete('/group-events/$eventId/like');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('unlikeEvent 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 新增留言
  ///
  /// [eventId] 揪團 ID
  /// [userId] 使用者 ID
  /// [content] 留言內容
  @override
  Future<GroupEventComment> addComment({
    required String eventId,
    required String userId,
    required String content,
  }) async {
    try {
      LogService.info('新增揪團留言: $eventId', source: _source);

      final response = await _apiClient.post('/group-events/$eventId/comments', data: {'content': content});

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      return GroupEventComment.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      LogService.error('addComment 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 取得留言列表
  ///
  /// [eventId] 揪團 ID
  @override
  Future<List<GroupEventComment>> getComments({required String eventId}) async {
    try {
      LogService.info('獲取揪團留言列表: $eventId', source: _source);

      final response = await _apiClient.get('/group-events/$eventId/comments');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> commentsJson = response.data as List<dynamic>;
      return commentsJson.map((c) => GroupEventComment.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      LogService.error('getComments 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除留言
  ///
  /// [commentId] 留言 ID
  /// [userId] 使用者 ID (需為留言者)
  @override
  Future<void> deleteComment({required String commentId, required String userId}) async {
    try {
      LogService.info('刪除留言: $commentId', source: _source);

      final response = await _apiClient.delete('/group-events/comments/$commentId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deleteComment 失敗: $e', source: _source);
      rethrow;
    }
  }
}
