import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/di.dart';
import '../data/models/poll.dart';
import '../services/poll_service.dart';
import '../services/log_service.dart';
import '../services/toast_service.dart';

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

  PollProvider() {
    _loadUserId();
  }

  PollService get _pollService => getIt<PollService>();

  Future<void> _loadUserId() async {
    final prefs = getIt<SharedPreferences>();
    _currentUserId = prefs.getString(PrefKeys.username);

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _currentUserId = 'User_${DateTime.now().millisecondsSinceEpoch}'; // Fallback
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

      // Refresh User ID just in case
      final prefs = getIt<SharedPreferences>();
      final user = prefs.getString(PrefKeys.username);
      if (user != null && user.isNotEmpty) _currentUserId = user;

      _polls = await _pollService.fetchPolls(userId: _currentUserId ?? 'anonymous');

      // Sort: Active first, then by date desc
      _polls.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      _lastSyncTime = DateTime.now();
      LogService.info('投票同步成功，載入 ${_polls.length} 個投票', source: _source);
      ToastService.success('投票同步成功！');
    } catch (e) {
      _error = e.toString();
      LogService.error('Provider fetch error: $e', source: _source);
      ToastService.error('投票同步失敗：$e');
    } finally {
      _setLoading(false);
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
    _setLoading(true);
    try {
      await _pollService.createPoll(
        title: title,
        description: description,
        creatorId: _currentUserId ?? 'anonymous',
        deadline: deadline,
        isAllowAddOption: isAllowAddOption,
        maxOptionLimit: maxOptionLimit,
        allowMultipleVotes: allowMultipleVotes,
        initialOptions: initialOptions,
      );
      await fetchPolls(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> votePoll({required String pollId, required List<String> optionIds}) async {
    _setLoading(true);
    try {
      await _pollService.votePoll(
        pollId: pollId,
        optionIds: optionIds,
        userId: _currentUserId ?? 'anonymous',
        userName: _currentUserId ?? 'Anonymous',
      );
      await fetchPolls(); // Refresh to get updated counts
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> addOption({required String pollId, required String text}) async {
    _setLoading(true);
    try {
      await _pollService.addOption(pollId: pollId, text: text, creatorId: _currentUserId ?? 'anonymous');
      await fetchPolls();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteOption({required String optionId}) async {
    _setLoading(true);
    try {
      await _pollService.deleteOption(optionId: optionId, userId: _currentUserId ?? 'anonymous');
      await fetchPolls();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> closePoll({required String pollId}) async {
    _setLoading(true);
    try {
      await _pollService.closePoll(pollId: pollId, userId: _currentUserId ?? 'anonymous');
      await fetchPolls();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePoll({required String pollId}) async {
    _setLoading(true);
    try {
      await _pollService.deletePoll(pollId: pollId, userId: _currentUserId ?? 'anonymous');
      await fetchPolls();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
