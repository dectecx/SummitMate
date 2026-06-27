import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_group_event_local_data_source.dart';
import '../datasources/interfaces/i_group_event_remote_data_source.dart';
import '../../domain/domain.dart';
import 'base/repository_remote_access.dart';

/// 揪團 Repository 實作（B 模式：讀快取／寫線上）
///
/// 讀取（[getAll]/[getById]/applications）回傳本地快取；所有遠端拉取與寫入
/// （建立、更新、刪除、申請、審核、按讚、留言等）皆經 [RepositoryRemoteAccess.online]
/// 守門：離線時回傳 `OfflineException` 而非發出網路請求，成功後更新本地快取。
@LazySingleton(as: IGroupEventRepository)
class GroupEventRepository with RepositoryRemoteAccess implements IGroupEventRepository {
  final IGroupEventLocalDataSource _localDataSource;
  final IGroupEventRemoteDataSource _remoteDataSource;

  @override
  final IConnectivityService connectivity;

  DateTime? _lastSyncTime;

  GroupEventRepository(this._localDataSource, this._remoteDataSource, this.connectivity);

  @override
  Future<Result<void, Exception>> init() async {
    _lastSyncTime = await _localDataSource.getLastSyncTime();
    return const Success(null);
  }

  // ── 讀取：本地快取 ──

  @override
  Future<List<GroupEvent>> getAll() => _localDataSource.getAllEvents();

  @override
  Future<GroupEvent?> getById(String eventId) => _localDataSource.getEventById(eventId);

  @override
  Future<void> save(GroupEvent event) => _localDataSource.saveEvent(event);

  @override
  Future<void> saveAll(List<GroupEvent> events) => _localDataSource.saveEvents(events);

  @override
  Future<void> delete(String eventId) => _localDataSource.deleteEvent(eventId);

  @override
  Future<Result<void, Exception>> clearAll() async {
    await _localDataSource.clear();
    return const Success(null);
  }

  @override
  DateTime? getLastSyncTime() => _lastSyncTime;

  @override
  Future<List<GroupEventApplication>> getAllApplications() => _localDataSource.getAllApplications();

  @override
  Future<void> saveApplications(List<GroupEventApplication> applications) =>
      _localDataSource.saveApplications(applications);

  // ── 遠端拉取：線上守門，成功寫回快取 ──

  @override
  Future<Result<List<GroupEvent>, Exception>> syncEvents({GroupEventCategory? category}) async {
    final result = await online<PaginatedList<GroupEvent>>(
      'syncEvents',
      () => _remoteDataSource.getEvents(category: category),
      cache: (value) async {
        await _localDataSource.saveEvents(value.items);
        _lastSyncTime = DateTime.now();
        await _localDataSource.saveLastSyncTime(_lastSyncTime!);
      },
    );
    return switch (result) {
      Success<PaginatedList<GroupEvent>, Exception>(value: final v) => Success(v.items),
      Failure<PaginatedList<GroupEvent>, Exception>(exception: final e) => Failure(e),
    };
  }

  @override
  Future<Result<GroupEvent, Exception>> syncEventById(String eventId) {
    return online<GroupEvent>(
      'syncEventById',
      () => _remoteDataSource.getEventById(eventId),
      cache: (event) => _localDataSource.saveEvent(event),
    );
  }

  @override
  Future<Result<PaginatedList<GroupEvent>, Exception>> syncMyEvents({
    required String type,
    int? page,
    int? limit,
  }) {
    return online<PaginatedList<GroupEvent>>(
      'syncMyEvents',
      () => _remoteDataSource.getMyEvents(type: type, page: page, limit: limit),
      cache: (value) => _localDataSource.saveEvents(value.items),
    );
  }

  // ── 寫入：線上守門 ──

  @override
  Future<Result<String, Exception>> create({
    required String title,
    required String description,
    required GroupEventCategory category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
    required String hostId,
    bool approvalRequired = false,
    String privateMessage = '',
    String? linkedTripId,
  }) {
    return online<String>(
      'createEvent',
      () => _remoteDataSource.createEvent(
        title: title,
        description: description,
        category: category,
        eventDate: eventDate,
        eventLocation: eventLocation,
        maxParticipants: maxParticipants,
        deadline: deadline,
        approvalRequired: approvalRequired,
        privateMessage: privateMessage,
        linkedTripId: linkedTripId,
      ),
    );
  }

  @override
  Future<Result<void, Exception>> update(GroupEvent event) async {
    final result = await online<GroupEvent>(
      'updateEvent',
      () => _remoteDataSource.updateEvent(event),
      cache: (updated) => _localDataSource.saveEvent(updated),
    );
    return switch (result) {
      Success<GroupEvent, Exception>() => const Success(null),
      Failure<GroupEvent, Exception>(exception: final e) => Failure(e),
    };
  }

  @override
  Future<Result<void, Exception>> remove({required String eventId, required String userId}) {
    return online<void>(
      'removeEvent',
      () => _remoteDataSource.deleteEvent(eventId),
      cache: (_) => _localDataSource.deleteEvent(eventId),
    );
  }

  @override
  Future<Result<void, Exception>> apply({required String eventId, required String userId, String? note}) async {
    final result = await online<String>('applyEvent', () => _remoteDataSource.applyEvent(eventId: eventId, note: note));
    if (result is Success<String, Exception>) {
      await syncEventById(eventId);
      return const Success(null);
    }
    return Failure((result as Failure<String, Exception>).exception);
  }

  @override
  Future<Result<void, Exception>> cancelApplication({String? eventId, required String applicationId}) async {
    final result = await online<void>(
      'cancelApplication',
      () => _remoteDataSource.cancelApplication(applicationId),
    );
    if (result is Success<void, Exception> && eventId != null) {
      await syncEventById(eventId);
    }
    return result;
  }

  @override
  Future<Result<List<GroupEventApplication>, Exception>> getApplications({required String eventId}) {
    return online<List<GroupEventApplication>>(
      'getApplications',
      () => _remoteDataSource.getEventApplications(eventId),
    );
  }

  @override
  Future<Result<void, Exception>> reviewApplication({
    String? eventId,
    required String applicationId,
    required GroupEventReviewAction action,
    String? note,
  }) async {
    final result = await online<void>(
      'reviewApplication',
      () => _remoteDataSource.reviewApplication(applicationId: applicationId, action: action, note: note),
    );
    if (result is Success<void, Exception> && eventId != null) {
      await syncEventById(eventId);
    }
    return result;
  }

  @override
  Future<Result<void, Exception>> closeEvent({required String eventId, required String userId}) {
    return online<void>('closeEvent', () => _remoteDataSource.closeEvent(eventId));
  }

  @override
  Future<Result<void, Exception>> likeEvent({required String eventId, required String userId}) {
    return online<void>(
      'likeEvent',
      () => _remoteDataSource.likeEvent(eventId),
      cache: (_) async {
        final event = await _localDataSource.getEventById(eventId);
        if (event != null) {
          await _localDataSource.saveEvent(event.copyWith(isLiked: true, likeCount: event.likeCount + 1));
        }
      },
    );
  }

  @override
  Future<Result<void, Exception>> unlikeEvent({required String eventId, required String userId}) {
    return online<void>(
      'unlikeEvent',
      () => _remoteDataSource.unlikeEvent(eventId),
      cache: (_) async {
        final event = await _localDataSource.getEventById(eventId);
        if (event != null) {
          await _localDataSource.saveEvent(event.copyWith(isLiked: false, likeCount: event.likeCount - 1));
        }
      },
    );
  }

  @override
  Future<Result<List<GroupEventComment>, Exception>> getComments({required String eventId}) {
    return online<List<GroupEventComment>>('getComments', () => _remoteDataSource.getComments(eventId));
  }

  @override
  Future<Result<GroupEventComment, Exception>> addComment({
    required String eventId,
    required String userId,
    required String content,
  }) {
    return online<GroupEventComment>(
      'addComment',
      () => _remoteDataSource.addComment(eventId: eventId, content: content),
    );
  }

  @override
  Future<Result<void, Exception>> deleteComment({required String commentId, required String userId}) {
    return online<void>('deleteComment', () => _remoteDataSource.deleteComment(commentId));
  }

  @override
  Future<Result<void, Exception>> updateLinkedTrip({required String eventId, String? linkedTripId}) async {
    final result = await online<void>(
      'updateLinkedTrip',
      () => _remoteDataSource.updateLinkedTrip(eventId: eventId, linkedTripId: linkedTripId),
    );
    if (result is Success<void, Exception>) {
      await syncEventById(eventId);
    }
    return result;
  }

  @override
  Future<Result<GroupEvent, Exception>> updateTripSnapshot(String eventId) {
    return online<GroupEvent>(
      'updateTripSnapshot',
      () => _remoteDataSource.updateTripSnapshot(eventId),
      cache: (event) => _localDataSource.saveEvent(event),
    );
  }
}
