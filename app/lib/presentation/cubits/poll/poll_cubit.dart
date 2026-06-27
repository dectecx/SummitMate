import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import 'package:summitmate/presentation/cubits/base/remote_sync_mixin.dart';
import 'package:summitmate/presentation/cubits/base/toast_notification.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';

import '../../../infrastructure/tools/log_service.dart';
import 'poll_state.dart';

@injectable
class PollCubit extends Cubit<PollState> with SafeEmitMixin<PollState>, RemoteSyncMixin<PollState> {
  final IPollRepository _pollRepository;
  final ITripRepository _tripRepository;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  static const String _source = 'PollCubit';

  PollCubit(this._pollRepository, this._tripRepository, this._connectivity, this._authService)
    : super(const PollInitial());

  // ──────────────────────────────────────────
  // RemoteSyncMixin overrides
  // ──────────────────────────────────────────

  @override
  IConnectivityService get connectivity => _connectivity;

  @override
  PollState withSyncing(PollState current, bool isSyncing) {
    if (current is PollLoaded) return current.copyWith(isSyncing: isSyncing);
    return current;
  }

  @override
  PollState withNotification(PollState current, ToastNotification notification) {
    if (current is PollLoaded) return current.copyWith(notification: notification);
    if (current is PollInitial) return PollInitial(notification: notification);
    if (current is PollLoading) return PollLoading(notification: notification);
    if (current is PollError) return PollError(current.message, notification: notification);
    return current;
  }

  // ──────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────

  String get _currentUserId => _authService.currentUserId ?? 'guest';

  Future<String?> get _currentTripId async {
    final result = await _tripRepository.getActiveTrip(_currentUserId);
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  /// 清除目前 State 的一次性 Toast 通知。由 UI [BlocListener] 在呈現 Toast 後呼叫。
  void clearNotification() {
    final s = state;
    if (s is PollLoaded) safeEmit(s.copyWith(clearNotification: true));
  }

  // ──────────────────────────────────────────
  // Load / Fetch
  // ──────────────────────────────────────────

  Future<void> loadPolls() async {
    safeEmit(const PollLoading());

    final tripId = await _currentTripId;
    if (tripId == null) {
      safeEmit(const PollError('尚未選擇行程'));
      return;
    }

    final polls = await _pollRepository.getByTripId(tripId);
    safeEmit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: null));
  }

  /// 透過 API 更新投票列表
  Future<void> fetchPolls({bool isAuto = false}) async {
    if (guardOffline('離線模式無法同步', isAuto: isAuto)) return;

    final tripId = await _currentTripId;
    if (tripId == null) return;

    if (state is PollLoaded) {
      safeEmit((state as PollLoaded).copyWith(isSyncing: true));
    } else {
      safeEmit(const PollLoading());
    }

    try {
      final result = await _pollRepository.refresh(tripId);
      final paginatedList = switch (result) {
        Success(value: final p) => p,
        Failure(exception: final e) => throw e,
      };

      final fetchedPolls = paginatedList.items;
      final now = DateTime.now();

      safeEmit(PollLoaded(
        polls: fetchedPolls,
        currentUserId: _currentUserId,
        lastSyncTime: now,
        isSyncing: false,
        notification: isAuto ? null : const ToastNotification.success('投票同步成功'),
      ));
    } catch (e) {
      LogService.error('Fetch polls failed: $e', source: _source);
      if (!isAuto) {
        final polls = await _pollRepository.getByTripId(tripId);
        safeEmit(PollLoaded(
          polls: polls,
          currentUserId: _currentUserId,
          lastSyncTime: null,
          isSyncing: false,
          notification: ToastNotification.error(AppErrorHandler.getUserMessage(e)),
        ));
      } else {
        if (state is PollLoaded) {
          safeEmit((state as PollLoaded).copyWith(isSyncing: false));
        } else if (state is PollLoading) {
          final polls = await _pollRepository.getByTripId(tripId);
          safeEmit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: null, isSyncing: false));
        }
      }
    }
  }

  // ──────────────────────────────────────────
  // Remote actions（透過 RemoteSyncMixin.runWithSyncGuard）
  // ──────────────────────────────────────────

  Future<bool> _performAction(
    Future<Result<void, Exception>> Function() action,
    String offlineMessage,
  ) async {
    return await runWithSyncGuard(
      offlineMessage: offlineMessage,
      action: () async {
        final result = await action();
        if (result is Failure) throw result.exception;
        await fetchPolls(isAuto: true);
      },
      logSource: _source,
    );
  }

  /// 建立投票
  Future<bool> createPoll({
    required String title,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    final tripId = await _currentTripId;
    if (tripId == null) return false;

    return await _performAction(
      () => _pollRepository.create(
        tripId: tripId,
        title: title,
        options: initialOptions,
        allowMultiple: allowMultipleVotes,
      ),
      '離線模式無法建立投票',
    );
  }

  /// 進行投票
  Future<bool> votePoll({required String pollId, required List<String> optionIds}) async {
    final tripId = await _currentTripId;
    if (tripId == null) return false;

    return await _performAction(
      () => _pollRepository.vote(tripId: tripId, pollId: pollId, optionIds: optionIds),
      '離線模式無法投票',
    );
  }

  /// 新增選項
  Future<bool> addOption({required String pollId, required String text}) async {
    final tripId = await _currentTripId;
    if (tripId == null) return false;

    return await _performAction(
      () => _pollRepository.addOption(tripId: tripId, pollId: pollId, optionText: text),
      '離線模式無法新增選項',
    );
  }

  /// 刪除投票
  Future<bool> deletePoll({required String pollId}) async {
    final tripId = await _currentTripId;
    if (tripId == null) return false;

    return await _performAction(
      () => _pollRepository.delete(tripId, pollId),
      '離線模式無法刪除投票',
    );
  }

  /// 關閉投票（TODO: 功能尚未支援）
  Future<bool> closePoll({required String pollId}) async {
    final s = state;
    final notification = const ToastNotification.info('關閉投票功能尚未支援');
    if (s is PollLoaded) {
      safeEmit(s.copyWith(notification: notification));
    } else {
      safeEmit(PollInitial(notification: notification));
    }
    return false;
  }

  /// 刪除選項（TODO: 功能尚未支援）
  Future<bool> deleteOption({required String pollId, required String optionId}) async {
    final s = state;
    final notification = const ToastNotification.info('刪除選項功能尚未支援');
    if (s is PollLoaded) {
      safeEmit(s.copyWith(notification: notification));
    } else {
      safeEmit(PollInitial(notification: notification));
    }
    return false;
  }

  void reset() {
    safeEmit(const PollInitial());
  }
}
