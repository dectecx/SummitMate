import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../models/message.dart';
import 'interfaces/i_message_repository.dart';

/// Message Repository
/// 管理留言的 CRUD 操作與同步
class MessageRepository implements IMessageRepository {
  static const String _boxName = HiveBoxNames.messages;

  Box<Message>? _box;

  /// 開啟 Box
  @override
  Future<void> init() async {
    _box = await Hive.openBox<Message>(_boxName);
  }

  /// 取得 Box
  Box<Message> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('MessageRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有留言
  @override
  List<Message> getAllMessages() {
    final messages = box.values.toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 依分類取得留言
  @override
  List<Message> getMessagesByCategory(String category) {
    final messages = box.values.where((m) => m.category == category).toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 取得主留言 (非回覆)
  @override
  List<Message> getMainMessages({String? category}) {
    var messages = box.values.where((m) => m.parentId == null);

    if (category != null) {
      messages = messages.where((m) => m.category == category);
    }

    final result = messages.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  /// 取得子留言 (回覆)
  @override
  List<Message> getReplies(String parentUuid) {
    final messages = box.values.where((m) => m.parentId == parentUuid).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// 依 UUID 取得留言
  @override
  Message? getByUuid(String uuid) {
    try {
      return box.values.firstWhere((m) => m.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  /// 新增留言
  @override
  Future<void> addMessage(Message message) async {
    await box.add(message);
  }

  /// 刪除留言 (依 UUID)
  @override
  Future<void> deleteByUuid(String uuid) async {
    final keyToDelete = box.keys.cast<dynamic>().firstWhere((key) => box.get(key)?.uuid == uuid, orElse: () => null);
    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }
  }

  /// 批次同步留言 (從雲端) - 完全覆蓋模式
  @override
  Future<void> syncFromCloud(List<Message> cloudMessages) async {
    // 清除現有資料，用雲端資料完全覆蓋
    await box.clear();

    // 寫入雲端資料
    for (final msg in cloudMessages) {
      await box.add(msg);
    }
  }

  /// 取得待上傳的本地留言 (尚未在雲端)
  @override
  List<Message> getPendingMessages(Set<String> cloudUuids) {
    return box.values.where((m) => !cloudUuids.contains(m.uuid)).toList();
  }

  /// 監聽留言變更
  @override
  Stream<BoxEvent> watchAllMessages() {
    return box.watch();
  }

  /// 儲存最後同步時間
  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString('msg_last_sync_time', time.toIso8601String());
  }

  /// 取得最後同步時間
  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString('msg_last_sync_time');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// 清除所有留言 (Debug 用途)
  @override
  Future<void> clearAll() async {
    await box.clear();
  }
}
