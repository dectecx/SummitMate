
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poll.dart';
import '../../core/constants.dart';
import '../../core/di.dart'; // Import for getIt

class PollRepository {
  static const String _boxName = HiveBoxNames.polls;
  static const String _lastSyncKey = 'poll_last_sync_time';

  Box<Poll>? _box;

  /// 初始化 Box
  Future<void> init() async {
    _box = await Hive.openBox<Poll>(_boxName);
  }

  /// 取得 Box (確保已初始化)
  Box<Poll> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('PollRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有投票
  List<Poll> getAllPolls() {
    return box.values.toList();
  }

  /// 儲存所有投票 (清除舊資料並寫入新資料)
  Future<void> savePolls(List<Poll> polls) async {
    await box.clear();
    await box.addAll(polls);
  }

  /// 清除所有投票
  Future<void> clearAll() async {
    await box.clear();
  }

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  /// 取得最後同步時間
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_lastSyncKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
