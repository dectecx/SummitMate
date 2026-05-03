import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';

import '../../../infrastructure/tools/log_service.dart';
import '../../../infrastructure/tools/toast_service.dart';
import 'poll_state.dart';

@injectable
class PollCubit extends Cubit<PollState> {
  final IPollRepository _pollRepository;
  final ITripRepository _tripRepository;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  static const String _source = 'PollCubit';

  PollCubit(this._pollRepository, this._tripRepository, this._connectivity, this._authService)
    : super(const PollInitial());

  String get _currentUserId {
    return _authService.currentUserId ?? 'guest';
  }

  bool get _isOffline => _connectivity.isOffline;

  Future<String?> get _currentTripId async {
    final result = await _tripRepository.getActiveTrip(_currentUserId);
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  Future<void> loadPolls() async {
    emit(const PollLoading());

    final tripId = await _currentTripId;
    if (tripId == null) {
      emit(const PollError('尚未選擇行程'));
      return;
    }

    // 從本地 Repo 載入
    final polls = await _pollRepository.getByTripId(tripId);

    // 初始載入
    emit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: null));
  }

  /// 透過 API 更新投票列表
  Future<void> fetchPolls({bool isAuto = false}) async {
    if (_isOffline) {
      if (!isAuto) ToastService.warning('離線模式無法同步');
      return;
    }

    final tripId = await _currentTripId;
    if (tripId == null) return;

    // 設定同步中狀態
    if (state is PollLoaded) {
      emit((state as PollLoaded).copyWith(isSyncing: true));
    } else {
      emit(const PollLoading());
    }

    try {
      final result = await _pollRepository.syncPolls(tripId);
      final paginatedList = switch (result) {
        Success(value: final p) => p,
        Failure(exception: final e) => throw e,
      };

      final fetchedPolls = paginatedList.items;
      final now = DateTime.now();

      emit(PollLoaded(polls: fetchedPolls, currentUserId: _currentUserId, lastSyncTime: now, isSyncing: false));

      if (!isAuto) ToastService.success('投票同步成功');
    } catch (e) {
      LogService.error('Fetch polls failed: $e', source: _source);
      if (!isAuto) {
        emit(PollError(AppErrorHandler.getUserMessage(e)));
        // 若失敗，恢復為舊資料的 Loaded 狀態
        final polls = await _pollRepository.getByTripId(tripId);
        emit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: null, isSyncing: false));
        ToastService.error(AppErrorHandler.getUserMessage(e));
      } else {
        if (state is PollLoaded) {
          emit((state as PollLoaded).copyWith(isSyncing: false));
        }
      }
    }
  }

  /// Action Helper
  Future<bool> _performAction(Future<Result<void, Exception>> Function() action, String offlineMessage) async {
    if (_isOffline) {
      ToastService.error(offlineMessage);
      return false;
    }

    if (state is PollLoaded) emit((state as PollLoaded).copyWith(isSyncing: true));

    try {
      final result = await action();
      if (result is Failure) throw result.exception;
      // Refetch to get updated state
      await fetchPolls(isAuto: true);
      return true;
    } catch (e) {
      LogService.error('Action failed: $e', source: _source);
      ToastService.error(AppErrorHandler.getUserMessage(e));
      if (state is PollLoaded) emit((state as PollLoaded).copyWith(isSyncing: false));
      return false;
    }
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

    return await _performAction(() => _pollRepository.delete(tripId, pollId), '離線模式無法刪除投票');
  }

  /// 關閉投票 (Mock / Not fully implemented in backend yet, using delete or skipping)
  Future<bool> closePoll({required String pollId}) async {
    // If backend supports close, call it here. For now, show info or throw unimp
    ToastService.info('關閉投票功能尚未支援');
    return false;
  }

  /// 刪除選項 (Mock / Not fully implemented in backend yet)
  Future<bool> deleteOption({required String pollId, required String optionId}) async {
    ToastService.info('刪除選項功能尚未支援');
    return false;
  }

  void reset() {
    emit(const PollInitial());
  }
}
