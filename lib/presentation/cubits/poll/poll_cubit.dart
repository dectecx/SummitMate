import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../../data/repositories/interfaces/i_poll_repository.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../domain/interfaces/i_poll_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../infrastructure/tools/toast_service.dart';
import 'poll_state.dart';

class PollCubit extends Cubit<PollState> {
  final IPollService _pollService;
  final IPollRepository _pollRepository;
  final IConnectivityService _connectivity;
  final SharedPreferences _prefs;

  static const String _source = 'PollCubit';
  static const Duration _syncCooldown = Duration(minutes: 5);

  PollCubit({
    IPollService? pollService,
    IPollRepository? pollRepository,
    IConnectivityService? connectivity,
    SharedPreferences? prefs,
  }) : _pollService = pollService ?? getIt<IPollService>(),
       _pollRepository = pollRepository ?? getIt<IPollRepository>(),
       _connectivity = connectivity ?? getIt<IConnectivityService>(),
       _prefs = prefs ?? getIt<SharedPreferences>(),
       super(const PollInitial());

  String get _currentUserId {
    String? user = _prefs.getString(PrefKeys.username);
    if (user == null || user.isEmpty) {
      user = 'User_${DateTime.now().millisecondsSinceEpoch}'; // Fallback
    }
    return user;
  }

  bool get _isOffline => _connectivity.isOffline;

  Future<void> loadPolls() async {
    emit(const PollLoading());

    // Load from local repo
    final polls = _pollRepository.getAllPolls();
    final lastSync = _pollRepository.getLastSyncTime();

    // Initial load
    emit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: lastSync));

    // Try fetch if online and stale
    // Logic similar to Provider's isAuto logic?
    // Maybe best to let UI trigger explicit refresh or simple load.
    // Let's just load from local first.
  }

  Future<void> fetchPolls({bool isAuto = false}) async {
    if (state is! PollLoaded) {
      // If not loaded yet, assume loading
      // But fetchPolls might be called after loadPolls
    }

    if (_isOffline) {
      if (!isAuto) ToastService.warning('離線模式無法同步');
      return;
    }

    // Cooldown check for auto sync
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

    // Set syncing state
    if (state is PollLoaded) {
      emit((state as PollLoaded).copyWith(isSyncing: true));
    } else {
      emit(const PollLoading());
    }

    try {
      final fetchedPolls = await _pollService.getPolls(userId: _currentUserId);

      // Save to repo
      await _pollRepository.savePolls(fetchedPolls);
      final now = DateTime.now();
      await _pollRepository.saveLastSyncTime(now);

      emit(PollLoaded(polls: fetchedPolls, currentUserId: _currentUserId, lastSyncTime: now, isSyncing: false));

      if (!isAuto) ToastService.success('投票同步成功');
    } catch (e) {
      LogService.error('Fetch polls failed: $e', source: _source);
      if (!isAuto) {
        emit(PollError(e.toString()));
        // If error, reverting to Loaded with old data?
        // If we emit Error, we lose the data view.
        // Better strategy: emit Loaded with isSyncing false and show toast.
        // Reload from local to ensure state consistency?
        final polls = _pollRepository.getAllPolls();
        final lastSync = _pollRepository.getLastSyncTime();
        emit(PollLoaded(polls: polls, currentUserId: _currentUserId, lastSyncTime: lastSync, isSyncing: false));
        ToastService.error('同步失敗: $e');
      } else {
        // Silent fail, just reset syncing flag
        if (state is PollLoaded) {
          emit((state as PollLoaded).copyWith(isSyncing: false));
        }
      }
    }
  }

  /// Action Helper
  Future<bool> _performAction(Future<void> Function() action, String offlineMessage) async {
    if (_isOffline) {
      ToastService.error(offlineMessage);
      return false;
    }

    if (state is PollLoaded) emit((state as PollLoaded).copyWith(isSyncing: true));

    try {
      await action();
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

  Future<bool> addOption({required String pollId, required String text}) async {
    return await _performAction(
      () => _pollService.addOption(pollId: pollId, text: text, creatorId: _currentUserId),
      '離線模式無法新增選項',
    );
  }

  Future<bool> deleteOption({required String pollId, required String optionId}) async {
    return await _performAction(
      () => _pollService.deleteOption(optionId: optionId, userId: _currentUserId),
      '離線模式無法刪除選項',
    );
  }

  Future<bool> closePoll({required String pollId}) async {
    return await _performAction(() => _pollService.closePoll(pollId: pollId, userId: _currentUserId), '離線模式無法結束投票');
  }

  Future<bool> deletePoll({required String pollId}) async {
    return await _performAction(() => _pollService.deletePoll(pollId: pollId, userId: _currentUserId), '離線模式無法刪除投票');
  }

  void reset() {
    emit(const PollInitial());
  }
}
