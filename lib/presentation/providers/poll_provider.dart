import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/poll.dart';
import '../../data/repositories/interfaces/i_poll_repository.dart';
import '../../data/repositories/interfaces/i_settings_repository.dart';
import '../../services/poll_service.dart';
import '../../services/log_service.dart';
import '../../services/toast_service.dart';

class PollProvider with ChangeNotifier {
  static const String _source = 'PollProvider';
  static const Duration _syncCooldown = Duration(minutes: 5);

  List<Poll> _polls = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  DateTime? _lastSyncTime;

  // Getters
  List<Poll> get polls => _polls;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Filtered Getters
  List<Poll> get activePolls => _polls.where((p) => p.isActive).toList();
  List<Poll> get endedPolls => _polls.where((p) => !p.isActive).toList();
  List<Poll> get myPolls => _polls.where((p) => p.creatorId == _currentUserId).toList();

  final PollService _pollService;
  final IPollRepository _pollRepository;
  final ISettingsRepository _settingsRepo;
  final SharedPreferences _prefs;

  PollProvider({
    PollService? pollService,
    IPollRepository? pollRepository,
    ISettingsRepository? settingsRepo,
    SharedPreferences? prefs,
  }) : _pollService = pollService ?? getIt<PollService>(),
       _pollRepository = pollRepository ?? getIt<IPollRepository>(),
       _settingsRepo = settingsRepo ?? getIt<ISettingsRepository>(),
       _prefs = prefs ?? getIt<SharedPreferences>() {
    _loadUserId();
    _loadInitialData();
  }

  bool get _isOffline => _settingsRepo.getSettings().isOfflineMode;

  Future<void> _loadUserId() async {
    _currentUserId = _prefs.getString(PrefKeys.username);

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _currentUserId = 'User_${DateTime.now().millisecondsSinceEpoch}'; // Fallback
    }
  }

  /// 載入初始資料 (從本地快取)
  void _loadInitialData() {
    _polls = _pollRepository.getAllPolls();
    _lastSyncTime = _pollRepository.getLastSyncTime();

    _polls.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (_polls.isNotEmpty) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 取得投票列表
  /// [isAuto] 為 true 時會套用 5 分鐘節流
  Future<void> fetchPolls({bool isAuto = false}) async {
    // 節流：自動同步時檢查冷卻時間
    // Ensure loaded
    _lastSyncTime ??= _pollRepository.getLastSyncTime();

    // 離線模式檢查
    if (_isOffline) {
      if (!isAuto) {
        ToastService.warning('離線模式無法同步');
      }
      return;
    }

    if (isAuto && _lastSyncTime != null) {
      final elapsed = DateTime.now().difference(_lastSyncTime!);
      if (elapsed < _syncCooldown) {
        LogService.debug('投票同步跳過 (節流中，剩餘 ${(_syncCooldown - elapsed).inSeconds}s)', source: _source);
        return;
      }
    }

    _setLoading(true);
    _error = null;
    try {
      LogService.info('開始同步投票...', source: _source);

      // Refresh User ID
      final user = _prefs.getString(PrefKeys.username);
      if (user != null && user.isNotEmpty) _currentUserId = user;

      final fetchedPolls = await _pollService.fetchPolls(userId: _currentUserId ?? 'anonymous');

      // Sort: Active first, then date desc
      fetchedPolls.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      _polls = fetchedPolls;

      // Save to cache
      await _pollRepository.savePolls(_polls);

      _lastSyncTime = DateTime.now();
      await _pollRepository.saveLastSyncTime(_lastSyncTime!);

      LogService.info('投票同步成功，載入 ${_polls.length} 個投票', source: _source);
      ToastService.success('投票同步成功！');
    } catch (e) {
      _error = e.toString();
      LogService.error('Provider fetch error: $e', source: _source);
      // Don't clear _polls on error, keep the cached version
      // But show error toast
      if (_polls.isEmpty) {
        // Only show loud error if we have no data at all, otherwise silent fail with stale data
        ToastService.error('投票同步失敗：$e');
      } else {
        ToastService.error('無法更新投票資料，顯示離線版本');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _performAction(Future<void> Function() action, {required String offlineMessage}) async {
    if (_isOffline) {
      ToastService.error(offlineMessage);
      return false;
    }
    _setLoading(true);
    try {
      await action();
      await fetchPolls();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false); // fetchPolls handles loading inside, but on error we must reset if not calling fetchPolls
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
    return _performAction(
      () => _pollService.createPoll(
        title: title,
        description: description,
        creatorId: _currentUserId ?? 'anonymous',
        deadline: deadline,
        isAllowAddOption: isAllowAddOption,
        maxOptionLimit: maxOptionLimit,
        allowMultipleVotes: allowMultipleVotes,
        initialOptions: initialOptions,
      ),
      offlineMessage: '離線模式無法建立投票',
    );
  }

  Future<bool> votePoll({required String pollId, required List<String> optionIds}) async {
    return _performAction(
      () => _pollService.votePoll(
        pollId: pollId,
        optionIds: optionIds,
        userId: _currentUserId ?? 'anonymous',
        userName: _currentUserId ?? 'Anonymous',
      ),
      offlineMessage: '離線模式無法投票',
    );
  }

  Future<bool> addOption({required String pollId, required String text}) async {
    return _performAction(
      () => _pollService.addOption(pollId: pollId, text: text, creatorId: _currentUserId ?? 'anonymous'),
      offlineMessage: '離線模式無法新增選項',
    );
  }

  Future<bool> deleteOption({required String optionId}) async {
    return _performAction(
      () => _pollService.deleteOption(optionId: optionId, userId: _currentUserId ?? 'anonymous'),
      offlineMessage: '離線模式無法刪除選項',
    );
  }

  Future<bool> closePoll({required String pollId}) async {
    return _performAction(
      () => _pollService.closePoll(pollId: pollId, userId: _currentUserId ?? 'anonymous'),
      offlineMessage: '離線模式無法結束投票',
    );
  }

  Future<bool> deletePoll({required String pollId}) async {
    return _performAction(
      () => _pollService.deletePoll(pollId: pollId, userId: _currentUserId ?? 'anonymous'),
      offlineMessage: '離線模式無法刪除投票',
    );
  }
}
