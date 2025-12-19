import 'package:hive/hive.dart';
import '../models/message.dart';

/// Message Repository
/// 管理留言的 CRUD 操作與同步
class MessageRepository {
  static const String _boxName = 'messages';

  Box<Message>? _box;

  /// 開啟 Box
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
  List<Message> getAllMessages() {
    final messages = box.values.toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 依分類取得留言
  List<Message> getMessagesByCategory(String category) {
    final messages = box.values.where((m) => m.category == category).toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 取得主留言 (非回覆)
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
  List<Message> getReplies(String parentUuid) {
    final messages = box.values.where((m) => m.parentId == parentUuid).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// 依 UUID 取得留言
  Message? getByUuid(String uuid) {
    try {
      return box.values.firstWhere((m) => m.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  /// 新增留言
  Future<void> addMessage(Message message) async {
    await box.add(message);
  }

  /// 刪除留言 (依 UUID)
  Future<void> deleteByUuid(String uuid) async {
    final keyToDelete = box.keys.cast<dynamic>().firstWhere((key) => box.get(key)?.uuid == uuid, orElse: () => null);
    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }
  }

  /// 批次同步留言 (從雲端) - 完全覆蓋模式
  Future<void> syncFromCloud(List<Message> cloudMessages) async {
    // 清除現有資料，用雲端資料完全覆蓋
    await box.clear();

    // 寫入雲端資料
    for (final msg in cloudMessages) {
      await box.add(msg);
    }
  }

  /// 取得待上傳的本地留言 (尚未在雲端)
  List<Message> getPendingMessages(Set<String> cloudUuids) {
    return box.values.where((m) => !cloudUuids.contains(m.uuid)).toList();
  }

  /// 監聽留言變更
  Stream<BoxEvent> watchAllMessages() {
    return box.watch();
  }

  /// 清除所有留言 (Debug 用途)
  Future<void> clearAll() async {
    await box.clear();
  }
}
