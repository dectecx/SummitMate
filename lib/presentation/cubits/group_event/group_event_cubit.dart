import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../core/error/result.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../domain/interfaces/i_auth_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../infrastructure/tools/toast_service.dart';
import '../../../data/repositories/interfaces/i_group_event_repository.dart';
import '../../../domain/interfaces/i_group_event_service.dart';
import 'group_event_state.dart';

class GroupEventCubit extends Cubit<GroupEventState> {
  final IGroupEventService _groupEventService;
  final IGroupEventRepository _groupEventRepository;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  static const String _source = 'GroupEventCubit';
  static const Duration _syncCooldown = Duration(minutes: 5);
  static const String _guestUserId = 'guest';

  GroupEventCubit({
    IGroupEventService? groupEventService,
    IGroupEventRepository? groupEventRepository,
    IConnectivityService? connectivity,
    IAuthService? authService,
  }) : _groupEventService = groupEventService ?? getIt<IGroupEventService>(),
       _groupEventRepository = groupEventRepository ?? getIt<IGroupEventRepository>(),
       _connectivity = connectivity ?? getIt<IConnectivityService>(),
       _authService = authService ?? getIt<IAuthService>(),
       super(const GroupEventInitial());

  String get _currentUserId => _authService.currentUserId ?? _guestUserId;
  bool get _isGuest => _currentUserId == _guestUserId || _currentUserId.isEmpty;
  bool get _isOffline => _connectivity.isOffline;

  /// Load events from local repository
  Future<void> loadEvents() async {
    emit(const GroupEventLoading());

    final events = _groupEventRepository.getAll();
    final lastSync = _groupEventRepository.getLastSyncTime();

    emit(GroupEventLoaded(events: events, currentUserId: _currentUserId, lastSyncTime: lastSync, isGuest: _isGuest));
  }

  /// Fetch events from API
  Future<void> fetchEvents({bool isAuto = false}) async {
    if (_isOffline) {
      if (!isAuto) ToastService.warning('離線模式無法使用揪團功能');
      return;
    }

    // Cooldown check for auto sync
    if (isAuto && state is GroupEventLoaded) {
      final lastSync = (state as GroupEventLoaded).lastSyncTime;
      if (lastSync != null && DateTime.now().difference(lastSync) < _syncCooldown) {
        LogService.debug('GroupEvent sync throttled', source: _source);
        return;
      }
    }

    // Show syncing state
    if (state is GroupEventLoaded) {
      emit((state as GroupEventLoaded).copyWith(isSyncing: true));
    } else {
      emit(const GroupEventLoading());
    }

    try {
      final result = await _groupEventService.getEvents(userId: _currentUserId);
      final fetchedEvents = switch (result) {
        Success(value: final e) => e,
        Failure(exception: final e) => throw e,
      };

      await _groupEventRepository.saveAll(fetchedEvents);
      final now = DateTime.now();

      emit(
        GroupEventLoaded(
          events: fetchedEvents,
          currentUserId: _currentUserId,
          lastSyncTime: now,
          isSyncing: false,
          isGuest: _isGuest,
        ),
      );

      if (!isAuto) ToastService.success('揪團同步成功');
    } catch (e) {
      LogService.error('Fetch group events failed: $e', source: _source);
      if (!isAuto) {
        final events = _groupEventRepository.getAll();
        final lastSync = DateTime.now();
        emit(
          GroupEventLoaded(
            events: events,
            currentUserId: _currentUserId,
            lastSyncTime: lastSync,
            isSyncing: false,
            isGuest: _isGuest,
          ),
        );
        ToastService.error('同步失敗: $e');
      } else {
        if (state is GroupEventLoaded) {
          emit((state as GroupEventLoaded).copyWith(isSyncing: false));
        }
      }
    }
  }

  /// Helper for actions requiring authentication
  Future<bool> _performAction(
    Future<Result<dynamic, Exception>> Function() action,
    String offlineMessage,
    String guestMessage,
  ) async {
    if (_isGuest) {
      ToastService.warning(guestMessage);
      return false;
    }
    if (_isOffline) {
      ToastService.error(offlineMessage);
      return false;
    }

    if (state is GroupEventLoaded) {
      emit((state as GroupEventLoaded).copyWith(isSyncing: true));
    }

    try {
      final result = await action();
      if (result is Failure) throw result.exception;
      await fetchEvents(isAuto: false);
      return true;
    } catch (e) {
      LogService.error('Action failed: $e', source: _source);
      ToastService.error('操作失敗: $e');
      if (state is GroupEventLoaded) {
        emit((state as GroupEventLoaded).copyWith(isSyncing: false));
      }
      return false;
    }
  }

  /// Create a new group event
  Future<bool> createEvent({
    required String title,
    String description = '',
    String location = '',
    required DateTime startDate,
    DateTime? endDate,
    required int maxMembers,
    bool approvalRequired = false,
    String privateMessage = '',
  }) async {
    return await _performAction(
      () => _groupEventService.createEvent(
        creatorId: _currentUserId,
        title: title,
        description: description,
        location: location,
        startDate: startDate,
        endDate: endDate,
        maxMembers: maxMembers,
        approvalRequired: approvalRequired,
        privateMessage: privateMessage,
      ),
      '離線模式無法建立揪團',
      '請登入以建立揪團',
    );
  }

  /// Apply to an event
  Future<bool> applyEvent({required String eventId, String message = ''}) async {
    return await _performAction(
      () => _groupEventService.applyEvent(eventId: eventId, userId: _currentUserId, message: message),
      '離線模式無法報名',
      '請登入以報名揪團',
    );
  }

  /// Cancel application
  Future<bool> cancelApplication({required String applicationId}) async {
    return await _performAction(
      () => _groupEventService.cancelApplication(applicationId: applicationId, userId: _currentUserId),
      '離線模式無法取消報名',
      '請登入以取消報名',
    );
  }

  /// Review application (approve/reject)
  Future<bool> reviewApplication({required String applicationId, required String action}) async {
    return await _performAction(
      () => _groupEventService.reviewApplication(applicationId: applicationId, action: action, userId: _currentUserId),
      '離線模式無法審核報名',
      '請登入以審核報名',
    );
  }

  /// Close event
  Future<bool> closeEvent({required String eventId}) async {
    return await _performAction(
      () => _groupEventService.closeEvent(eventId: eventId, userId: _currentUserId),
      '離線模式無法關閉揪團',
      '請登入以關閉揪團',
    );
  }

  /// Like event (TODO)
  Future<bool> likeEvent({required String eventId}) async {
    // TODO: Implement like functionality
    ToastService.info('喜歡功能開發中');
    return false;
  }

  void reset() {
    emit(const GroupEventInitial());
  }
}
