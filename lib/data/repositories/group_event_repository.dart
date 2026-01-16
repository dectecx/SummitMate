import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/result.dart';
import '../../core/di.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_group_event_repository.dart';
import '../datasources/interfaces/i_group_event_local_data_source.dart';
import '../datasources/interfaces/i_group_event_remote_data_source.dart';
import '../models/group_event.dart';

/// 揪團 Repository (支援 Offline-First)
///
/// 協調 LocalDataSource (Hive) 與 RemoteDataSource (API) 的資料存取。
/// 採用 Hide mode，對外提供統一的資料存取介面。
class GroupEventRepository implements IGroupEventRepository {
  static const String _source = 'GroupEventRepository';
  static const String _lastSyncKey = 'group_event_last_sync_time';

  final IGroupEventLocalDataSource _localDataSource;
  final IGroupEventRemoteDataSource _remoteDataSource;

  GroupEventRepository({
    required IGroupEventLocalDataSource localDataSource,
    required IGroupEventRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      return const Success(null);
    } catch (e) {
      LogService.error('Init failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  // ========== Data Operations ==========

  @override
  List<GroupEvent> getAll() => _localDataSource.getAllEvents();

  @override
  GroupEvent? getById(String eventId) => _localDataSource.getEventById(eventId);

  @override
  Future<void> saveAll(List<GroupEvent> events) => _localDataSource.saveEvents(events);

  @override
  Future<void> save(GroupEvent event) => _localDataSource.saveEvent(event);

  @override
  Future<void> delete(String eventId) => _localDataSource.deleteEvent(eventId);

  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      LogService.info('Clearing all group events (Local)', source: _source);
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  // ========== Application Data Operations ==========

  @override
  List<GroupEventApplication> getAllApplications() => _localDataSource.getAllApplications();

  @override
  Future<void> saveApplications(List<GroupEventApplication> applications) =>
      _localDataSource.saveApplications(applications);

  // ========== Sync Operations ==========

  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_lastSyncKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  @override
  Future<Result<List<GroupEvent>, Exception>> syncEvents({String? category}) async {
    try {
      // Note: Remote API takes userId and status, category filtering done locally
      final userId = _getCurrentUserId();
      final events = await _remoteDataSource.getEvents(userId: userId, status: 'open');

      // Filter by category if specified
      final filtered = category != null ? events.where((e) => e.description.contains(category)).toList() : events;

      await _localDataSource.saveEvents(filtered);
      await _saveLastSyncTime(DateTime.now());
      LogService.info('Synced ${filtered.length} events', source: _source);
      return Success(filtered);
    } catch (e) {
      LogService.error('Sync events failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<GroupEvent, Exception>> syncEventById(String eventId) async {
    try {
      final userId = _getCurrentUserId();
      final event = await _remoteDataSource.getEvent(eventId: eventId, userId: userId);
      await _localDataSource.saveEvent(event);
      return Success(event);
    } catch (e) {
      LogService.error('Sync event by ID failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<List<GroupEventApplication>, Exception>> syncMyApplications(String userId) async {
    try {
      // Get my applied events and extract applications
      final events = await _remoteDataSource.getMyEvents(userId: userId, type: 'applied');
      // Applications are embedded in event data, extract from local after sync
      await _localDataSource.saveEvents(events);
      final applications = _localDataSource.getAllApplications();
      return Success(applications);
    } catch (e) {
      LogService.error('Sync my applications failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  String _getCurrentUserId() {
    // Get from auth service or return guest
    return 'guest'; // TODO: Inject auth service for proper user ID
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  // ========== Remote Write Operations ==========

  @override
  Future<Result<String, Exception>> create({
    required String title,
    required String description,
    required String category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
    required String creatorId,
  }) async {
    try {
      final event = GroupEvent(
        id: '',
        title: title,
        description: description,
        location: eventLocation,
        startDate: eventDate,
        endDate: deadline,
        maxMembers: maxParticipants,
        creatorId: creatorId,
        createdAt: DateTime.now(),
        createdBy: creatorId,
        updatedAt: DateTime.now(),
        updatedBy: creatorId,
      );
      final id = await _remoteDataSource.createEvent(event);
      LogService.info('Created event: $id', source: _source);
      return Success(id);
    } catch (e) {
      LogService.error('Create event failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> update(GroupEvent event) async {
    try {
      await _remoteDataSource.updateEvent(event, event.updatedBy);
      await _localDataSource.saveEvent(event);
      return const Success(null);
    } catch (e) {
      LogService.error('Update event failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> remove({required String eventId, required String userId}) async {
    try {
      await _remoteDataSource.deleteEvent(eventId: eventId, userId: userId);
      await _localDataSource.deleteEvent(eventId);
      LogService.info('Removed event: $eventId', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('Remove event failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> apply({required String eventId, required String userId, String? note}) async {
    try {
      await _remoteDataSource.applyEvent(eventId: eventId, userId: userId, message: note);
      return const Success(null);
    } catch (e) {
      LogService.error('Apply event failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> cancelApplication({required String eventId, required String userId}) async {
    try {
      await _remoteDataSource.cancelApplication(applicationId: eventId, userId: userId);
      return const Success(null);
    } catch (e) {
      LogService.error('Cancel application failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> reviewApplication({
    required String eventId,
    required String applicantUserId,
    required String reviewerId,
    required String action,
    String? note,
  }) async {
    try {
      await _remoteDataSource.reviewApplication(applicationId: eventId, action: action, userId: reviewerId);
      return const Success(null);
    } catch (e) {
      LogService.error('Review application failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
