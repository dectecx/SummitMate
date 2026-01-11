import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/message.dart';
import '../interfaces/i_message_local_data_source.dart';

/// 留言訊息 (Message) 的本地資料來源實作 (使用 Hive)
class MessageLocalDataSource implements IMessageLocalDataSource {
  static const String _boxName = HiveBoxNames.messages;
  static const String _prefKeyLastSync = 'msg_last_sync_time';

  Box<Message>? _box;

  /// 初始化 Hive Box
  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Message>(_boxName);
    } else {
      _box = Hive.box<Message>(_boxName);
    }
  }

  Box<Message> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('MessageLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有訊息
  @override
  List<Message> getAll() {
    return box.values.toList();
  }

  /// 透過 UUID 取得訊息
  ///
  /// [uuid] 訊息 UUID
  @override
  Message? getByUuid(String uuid) {
    try {
      return box.values.firstWhere((m) => m.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  /// 新增訊息
  ///
  /// [message] 欲新增的訊息物件
  @override
  Future<void> add(Message message) async {
    await box.add(message);
  }

  /// 刪除訊息
  ///
  /// [key] 訊息的本地鍵值 (Hive Key)
  @override
  Future<void> delete(dynamic key) async {
    await box.delete(key);
  }

  /// 清除所有訊息
  @override
  Future<void> clear() async {
    await box.clear();
  }

  /// 監聽資料變更
  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }

  /// 儲存最後同步時間
  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_prefKeyLastSync, time.toIso8601String());
  }

  /// 取得最後同步時間
  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_prefKeyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
