import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_group_event_local_data_source.dart';
import '../datasources/interfaces/i_group_event_remote_data_source.dart';
import '../../domain/domain.dart';

/// 揪團 Repository 實作
@LazySingleton(as: IGroupEventRepository)
class GroupEventRepository implements IGroupEventRepository {
  final IGroupEventLocalDataSource _localDataSource;
  final IGroupEventRemoteDataSource _remoteDataSource;

  GroupEventRepository(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

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
  DateTime? getLastSyncTime() => null;

  @override
  Future<Result<List<GroupEvent>, Exception>> syncEvents({GroupEventCategory? category}) async {
    try {
      final result = await _remoteDataSource.getEvents(category: category);
      if (result is Success<PaginatedList<GroupEvent>, Exception>) {
        await _localDataSource.saveEvents(result.value.items);
        return Success(result.value.items);
      }
      return Failure((result as Failure).exception);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<GroupEvent, Exception>> syncEventById(String eventId) async {
    try {
      final result = await _remoteDataSource.getEventById(eventId);
      if (result is Success<GroupEvent, Exception>) {
        await _localDataSource.saveEvent(result.value);
        return Success(result.value);
      }
      return Failure((result as Failure).exception);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> create({
    required String title,
    required String description,
    required GroupEventCategory category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
    required String creatorId,
    String? linkedTripId,
  }) async {
    return _remoteDataSource.createEvent(
      title: title,
      description: description,
      category: category,
      eventDate: eventDate,
      eventLocation: eventLocation,
      maxParticipants: maxParticipants,
      deadline: deadline,
      linkedTripId: linkedTripId,
    );
  }

  @override
  Future<Result<void, Exception>> update(GroupEvent event) async {
    // TODO: 實作雲端更新邏輯
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> remove({required String eventId, required String userId}) async {
    final result = await _remoteDataSource.deleteEvent(eventId);
    if (result is Success) {
      await _localDataSource.deleteEvent(eventId);
    }
    return result;
  }

  @override
  Future<Result<void, Exception>> apply({required String eventId, required String userId, String? note}) async {
    final result = await _remoteDataSource.applyEvent(eventId: eventId, note: note);
    if (result is Success) {
      await syncEventById(eventId);
    }
    return result is Success ? const Success(null) : Failure((result as Failure).exception);
  }

  @override
  Future<Result<void, Exception>> cancelApplication({required String eventId, required String userId}) async {
    final result = await _remoteDataSource.cancelApplication(eventId);
    if (result is Success) {
      await syncEventById(eventId);
    }
    return result;
  }

  @override
  Future<List<GroupEventApplication>> getAllApplications() => _localDataSource.getAllApplications();

  @override
  Future<void> saveApplications(List<GroupEventApplication> applications) =>
      _localDataSource.saveApplications(applications);

  @override
  Future<Result<List<GroupEventApplication>, Exception>> syncMyApplications(String userId) async {
    try {
      final result = await _remoteDataSource.getMyApplications();
      if (result is Success<List<GroupEventApplication>, Exception>) {
        await _localDataSource.saveApplications(result.value);
        return Success(result.value);
      }
      return Failure((result as Failure).exception);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<GroupEventApplication>, Exception>> getApplications({required String eventId}) async {
    return _remoteDataSource.getEventApplications(eventId);
  }

  @override
  Future<Result<void, Exception>> reviewApplication({
    required String eventId,
    required String applicantUserId,
    required String reviewerId,
    required String action,
    String? note,
  }) async {
    return _remoteDataSource.reviewApplication(
      eventId: eventId,
      applicantUserId: applicantUserId,
      action: action,
      note: note,
    );
  }

  @override
  Future<Result<void, Exception>> closeEvent({required String eventId, required String userId}) async {
    return _remoteDataSource.closeEvent(eventId);
  }

  @override
  Future<Result<void, Exception>> likeEvent({required String eventId, required String userId}) async {
    final result = await _remoteDataSource.likeEvent(eventId);
    if (result is Success) {
      final event = await _localDataSource.getEventById(eventId);
      if (event != null) {
        await _localDataSource.saveEvent(event.copyWith(isLiked: true, likeCount: event.likeCount + 1));
      }
    }
    return result;
  }

  @override
  Future<Result<void, Exception>> unlikeEvent({required String eventId, required String userId}) async {
    final result = await _remoteDataSource.unlikeEvent(eventId);
    if (result is Success) {
      final event = await _localDataSource.getEventById(eventId);
      if (event != null) {
        await _localDataSource.saveEvent(event.copyWith(isLiked: false, likeCount: event.likeCount - 1));
      }
    }
    return result;
  }

  @override
  Future<Result<List<GroupEventComment>, Exception>> getComments({required String eventId}) async {
    return _remoteDataSource.getComments(eventId);
  }

  @override
  Future<Result<GroupEventComment, Exception>> addComment({
    required String eventId,
    required String userId,
    required String content,
  }) async {
    return _remoteDataSource.addComment(eventId: eventId, content: content);
  }

  @override
  Future<Result<void, Exception>> deleteComment({required String commentId, required String userId}) async {
    return _remoteDataSource.deleteComment(commentId);
  }

  @override
  Future<Result<void, Exception>> updateLinkedTrip({required String eventId, String? linkedTripId}) async {
    final result = await _remoteDataSource.updateLinkedTrip(eventId: eventId, linkedTripId: linkedTripId);
    if (result is Success) {
      await syncEventById(eventId);
    }
    return result;
  }

  @override
  Future<Result<GroupEvent, Exception>> updateTripSnapshot(String eventId) async {
    try {
      final result = await _remoteDataSource.updateTripSnapshot(eventId);
      if (result is Success<GroupEvent, Exception>) {
        await _localDataSource.saveEvent(result.value);
        return Success(result.value);
      }
      return Failure((result as Failure).exception);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
