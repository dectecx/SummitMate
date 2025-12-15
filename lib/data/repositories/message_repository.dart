import 'package:isar/isar.dart';
import '../models/message.dart';

/// Message Repository
/// 管理留言的 CRUD 操作與同步
class MessageRepository {
  final Isar _isar;

  MessageRepository(this._isar);

  /// 取得所有留言
  Future<List<Message>> getAllMessages() async {
    return await _isar.messages
        .where()
        .sortByTimestampDesc()
        .findAll();
  }

  /// 依分類取得留言
  Future<List<Message>> getMessagesByCategory(String category) async {
    return await _isar.messages
        .filter()
        .categoryEqualTo(category)
        .sortByTimestampDesc()
        .findAll();
  }

  /// 取得主留言 (非回覆)
  Future<List<Message>> getMainMessages({String? category}) async {
    var query = _isar.messages.filter().parentIdIsNull();

    if (category != null) {
      query = query.categoryEqualTo(category);
    }

    return await query.sortByTimestampDesc().findAll();
  }

  /// 取得子留言 (回覆)
  Future<List<Message>> getReplies(String parentUuid) async {
    return await _isar.messages
        .filter()
        .parentIdEqualTo(parentUuid)
        .sortByTimestamp()
        .findAll();
  }

  /// 依 UUID 取得留言
  Future<Message?> getByUuid(String uuid) async {
    return await _isar.messages
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
  }

  /// 新增留言
  Future<void> addMessage(Message message) async {
    await _isar.writeTxn(() async {
      await _isar.messages.put(message);
    });
  }

  /// 刪除留言 (依 UUID)
  Future<void> deleteByUuid(String uuid) async {
    await _isar.writeTxn(() async {
      await _isar.messages.filter().uuidEqualTo(uuid).deleteFirst();
    });
  }

  /// 批次同步留言 (從雲端)
  Future<void> syncFromCloud(List<Message> cloudMessages) async {
    await _isar.writeTxn(() async {
      // 獲取現有 UUID 集合
      final existing = await _isar.messages.where().findAll();
      final existingUuids = existing.map((m) => m.uuid).toSet();

      // 新增或更新雲端留言
      for (final msg in cloudMessages) {
        if (!existingUuids.contains(msg.uuid)) {
          await _isar.messages.put(msg);
        }
      }

      // 移除雲端已刪除的留言
      final cloudUuids = cloudMessages.map((m) => m.uuid).toSet();
      for (final localMsg in existing) {
        if (!cloudUuids.contains(localMsg.uuid)) {
          await _isar.messages.delete(localMsg.id!);
        }
      }
    });
  }

  /// 取得待上傳的本地留言 (尚未在雲端)
  Future<List<Message>> getPendingMessages(Set<String> cloudUuids) async {
    final all = await getAllMessages();
    return all.where((m) => !cloudUuids.contains(m.uuid)).toList();
  }

  /// 監聽留言變更
  Stream<List<Message>> watchAllMessages() {
    return _isar.messages.where().watch(fireImmediately: true);
  }

  /// 清除所有留言 (Debug 用途)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.messages.clear();
    });
  }
}
