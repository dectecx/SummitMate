import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../core/error/result.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../domain/interfaces/i_auth_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../infrastructure/tools/toast_service.dart';
import '../../../data/repositories/interfaces/i_group_event_repository.dart';
import 'group_event_state.dart';

class GroupEventCubit extends Cubit<GroupEventState> {
  final IGroupEventRepository _groupEventRepository;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  static const String _source = 'GroupEventCubit';
  static const Duration _syncCooldown = Duration(minutes: 5);
  static const String _guestUserId = 'guest';

  final Map<String, DateTime> _likeDebounceMap = {};

  GroupEventCubit({
    IGroupEventRepository? groupEventRepository,
    IConnectivityService? connectivity,
    IAuthService? authService,
  }) : _groupEventRepository = groupEventRepository ?? getIt<IGroupEventRepository>(),
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
      final result = await _groupEventRepository.syncEvents();
      final fetchedEvents = switch (result) {
        Success(value: final e) => e,
        Failure(exception: final e) => throw e,
      };

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

  /// 執行需要認證的遠端操作
  ///
  /// 統一處理訪客檢查、離線檢查、同步狀態管理和錯誤處理。
  Future<bool> _executeRemoteAction(
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

  /// 建立新揪團
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
    return await _executeRemoteAction(
      () => _groupEventRepository.create(
        title: title,
        description: description,
        category: '', // TODO: Add category parameter
        eventDate: startDate,
        eventLocation: location,
        maxParticipants: maxMembers,
        deadline: endDate ?? startDate,
        creatorId: _currentUserId,
      ),
      '離線模式無法建立揪團',
      '請登入以建立揪團',
    );
  }

  /// 報名揪團
  Future<bool> applyEvent({required String eventId, String message = ''}) async {
    return await _executeRemoteAction(
      () => _groupEventRepository.apply(eventId: eventId, userId: _currentUserId, note: message),
      '離線模式無法報名',
      '請登入以報名揪團',
    );
  }

  /// 取消報名
  Future<bool> cancelApplication({required String applicationId}) async {
    return await _executeRemoteAction(
      () => _groupEventRepository.cancelApplication(eventId: applicationId, userId: _currentUserId),
      '離線模式無法取消報名',
      '請登入以取消報名',
    );
  }

  /// 審核報名 (approve/reject)
  Future<bool> reviewApplication({required String applicationId, required String action}) async {
    return await _executeRemoteAction(
      () => _groupEventRepository.reviewApplication(
        eventId: applicationId,
        applicantUserId: '', // Filled by backend from applicationId
        reviewerId: _currentUserId,
        action: action,
      ),
      '離線模式無法審核報名',
      '請登入以審核報名',
    );
  }

  /// 關閉揪團
  Future<bool> closeEvent({required String eventId}) async {
    return await _executeRemoteAction(
      () => _groupEventRepository.closeEvent(eventId: eventId, userId: _currentUserId),
      '離線模式無法關閉揪團',
      '請登入以關閉揪團',
    );
  }

  /// 喜歡/取消喜歡揪團
  ///
  /// 委派呼叫 [IGroupEventRepository.likeEvent] 或 [unlikeEvent]，
  /// Repository 負責本地持久化和遠端 API 呼叫。
  Future<bool> likeEvent({required String eventId}) async {
    if (_isGuest) {
      ToastService.warning('請登入以收藏揪團');
      return false;
    }
    if (_isOffline) {
      ToastService.error('離線模式無法操作');
      return false;
    }

    // Debounce/Throttle (300ms) to prevent rapid clicks
    final now = DateTime.now();
    if (_likeDebounceMap.containsKey(eventId)) {
      final lastClick = _likeDebounceMap[eventId]!;
      if (now.difference(lastClick) < const Duration(milliseconds: 300)) {
        LogService.debug('Like event throttled for $eventId', source: _source);
        return false;
      }
    }
    _likeDebounceMap[eventId] = now;

    final currentState = state;
    if (currentState is! GroupEventLoaded) return false;

    // 找到目前的 event
    final event = currentState.events.firstWhere((e) => e.id == eventId, orElse: () => currentState.events.first);
    final wasLiked = event.isLiked;

    // Optimistic UI Update
    final updatedEvents = currentState.events.map((e) {
      if (e.id == eventId) {
        return e.copyWith(isLiked: !wasLiked, likeCount: wasLiked ? e.likeCount - 1 : e.likeCount + 1);
      }
      return e;
    }).toList();
    emit(currentState.copyWith(events: updatedEvents));

    // 委派給 Repository (含本地持久化 + API 呼叫)
    final result = wasLiked
        ? await _groupEventRepository.unlikeEvent(eventId: eventId, userId: _currentUserId)
        : await _groupEventRepository.likeEvent(eventId: eventId, userId: _currentUserId);

    if (result is Failure) {
      LogService.error('Like event failed: ${result.exception}', source: _source);
      ToastService.error('操作失敗');

      // Repository 已處理 rollback，重新載入本地資料以同步 UI
      final freshEvents = _groupEventRepository.getAll();
      emit(currentState.copyWith(events: freshEvents));
      return false;
    }

    return true;
  }

  void reset() {
    emit(const GroupEventInitial());
  }
}
