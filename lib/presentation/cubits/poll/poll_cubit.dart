import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di.dart';
import '../../../data/repositories/interfaces/i_poll_repository.dart';
import '../../../core/error/result.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../domain/interfaces/i_poll_service.dart';
import '../../../domain/interfaces/i_auth_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../infrastructure/tools/toast_service.dart';
import 'poll_state.dart';

class PollCubit extends Cubit<PollState> {
  final IPollService _pollService;
  final IPollRepository _pollRepository;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  static const String _source = 'PollCubit';
  static const Duration _syncCooldown = Duration(minutes: 5);

  PollCubit({
    IPollService? pollService,
    IPollRepository? pollRepository,
    IConnectivityService? connectivity,
    IAuthService? authService,
    SharedPreferences? prefs,
  }) : _pollService = pollService ?? getIt<IPollService>(),
       _pollRepository = pollRepository ?? getIt<IPollRepository>(),
       _connectivity = connectivity ?? getIt<IConnectivityService>(),
       _authService = authService ?? getIt<IAuthService>(),
       super(const PollInitial());

  String get _currentUserId {
    return _authService.currentUserId ?? 'guest';
  }

  bool get _isOffline => _connectivity.isOffline;

  Future<void> loadPolls() async {
    emit(const PollLoading());

    // 從本地 Repo 載入
    final polls = _pollRepository.getAll();
    final lastSync = _pollRepository.getLastSyncTime();

    // 初始載入
    emit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: lastSync));

    // 若在線且資料過舊，可嘗試 fetch
    // 目前邏輯建議由 UI 觸發明確刷新
  }

  /// 透過 API 更新投票列表
  ///
  /// [isAuto] 是否為自動同步 (若是，失敗時不顯示錯誤 Dialog，僅 Log)
  Future<void> fetchPolls({bool isAuto = false}) async {
    if (state is! PollLoaded) {
      // 若尚未載入，可能需要先 emit loading?
      // 但通常 fetchPolls 會在 loadPolls 之後呼叫
    }

    if (_isOffline) {
      if (!isAuto) ToastService.warning('離線模式無法同步');
      return;
    }

    // 自動同步的冷卻檢查
    if (isAuto && state is PollLoaded) {
      final lastSync = (state as PollLoaded).lastSyncTime;
      if (lastSync != null) {
        final elapsed = DateTime.now().difference(lastSync);
        if (elapsed < _syncCooldown) {
          LogService.debug('Poll sync throttled', source: _source);
          return;
        }
      }
    }

    // 設定同步中狀態
    if (state is PollLoaded) {
      emit((state as PollLoaded).copyWith(isSyncing: true));
    } else {
      emit(const PollLoading());
    }

    try {
      final result = await _pollService.getPolls(userId: _currentUserId);
      final fetchedPolls = switch (result) {
        Success(value: final p) => p,
        Failure(exception: final e) => throw e,
      };

      // 儲存至 Repo
      await _pollRepository.saveAll(fetchedPolls);
      final now = DateTime.now();

      emit(PollLoaded(polls: fetchedPolls, currentUserId: _currentUserId, lastSyncTime: now, isSyncing: false));

      if (!isAuto) ToastService.success('投票同步成功');
    } catch (e) {
      LogService.error('Fetch polls failed: $e', source: _source);
      if (!isAuto) {
        emit(PollError(e.toString()));
        // 若失敗，恢復為舊資料的 Loaded 狀態?
        // 較好的策略：emit Loaded 但 isSyncing=false 並顯示 Toast
        final polls = _pollRepository.getAll();
        final lastSync = _pollRepository.getLastSyncTime();
        emit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: lastSync, isSyncing: false));
        ToastService.error('同步失敗: $e');
      } else {
        // 自動同步失敗則靜默處理，僅重置 flag
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
      await fetchPolls(isAuto: false); // Force sync after action
      return true;
    } catch (e) {
      LogService.error('Action failed: $e', source: _source);
      ToastService.error('操作失敗: $e');
      if (state is PollLoaded) emit((state as PollLoaded).copyWith(isSyncing: false));
      return false;
    }
  }

  /// 建立投票
  ///
  /// [title] 標題
  /// [description] 描述
  /// [deadline] 截止時間
  /// [isAllowAddOption] 是否允許新增選項
  /// [maxOptionLimit] 最大選項數限制
  /// [allowMultipleVotes] 是否允許複選
  /// [initialOptions] 初始選項列表
  Future<bool> createPoll({
    required String title,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    return await _performAction(
      () => _pollService.createPoll(
        title: title,
        description: description,
        creatorId: _currentUserId,
        deadline: deadline,
        isAllowAddOption: isAllowAddOption,
        maxOptionLimit: maxOptionLimit,
        allowMultipleVotes: allowMultipleVotes,
        initialOptions: initialOptions,
      ),
      '離線模式無法建立投票',
    );
  }

  /// 進行投票
  ///
  /// [pollId] 投票 ID
  /// [optionIds] 選項 ID 列表
  Future<bool> votePoll({required String pollId, required List<String> optionIds}) async {
    return await _performAction(
      () => _pollService.votePoll(
        pollId: pollId,
        optionIds: optionIds,
        userId: _currentUserId,
        userName: _currentUserId, // Using ID as name fallback or pref?
      ),
      '離線模式無法投票',
    );
  }

  /// 新增選項
  ///
  /// [pollId] 投票 ID
  /// [text] 選項文字
  Future<bool> addOption({required String pollId, required String text}) async {
    return await _performAction(
      () => _pollService.addOption(pollId: pollId, text: text, creatorId: _currentUserId),
      '離線模式無法新增選項',
    );
  }

  /// 刪除選項
  ///
  /// [pollId] 投票 ID
  /// [optionId] 選項 ID
  Future<bool> deleteOption({required String pollId, required String optionId}) async {
    return await _performAction(
      () => _pollService.deleteOption(optionId: optionId, userId: _currentUserId),
      '離線模式無法刪除選項',
    );
  }

  /// 結束投票
  ///
  /// [pollId] 投票 ID
  Future<bool> closePoll({required String pollId}) async {
    return await _performAction(() => _pollService.closePoll(pollId: pollId, userId: _currentUserId), '離線模式無法結束投票');
  }

  /// 刪除投票
  ///
  /// [pollId] 投票 ID
  Future<bool> deletePoll({required String pollId}) async {
    return await _performAction(() => _pollService.deletePoll(pollId: pollId, userId: _currentUserId), '離線模式無法刪除投票');
  }

  void reset() {
    emit(const PollInitial());
  }
}
