import '../../core/di.dart';
import '../../services/interfaces/i_connectivity_service.dart';
import '../../services/log_service.dart';
import '../models/message.dart';
import 'interfaces/i_message_repository.dart';
import '../datasources/interfaces/i_message_local_data_source.dart';
import '../datasources/interfaces/i_message_remote_data_source.dart';
import 'package:hive/hive.dart'; // For BoxEvent

/// Message Repository
/// Coordinates Local and Remote Data Sources
class MessageRepository implements IMessageRepository {
  static const String _source = 'MessageRepository';

  final IMessageLocalDataSource _localDataSource;
  final IMessageRemoteDataSource _remoteDataSource;
  final IConnectivityService _connectivity;

  MessageRepository({
    IMessageLocalDataSource? localDataSource,
    IMessageRemoteDataSource? remoteDataSource,
    IConnectivityService? connectivity,
  }) : _localDataSource = localDataSource ?? getIt<IMessageLocalDataSource>(),
       _remoteDataSource = remoteDataSource ?? getIt<IMessageRemoteDataSource>(),
       _connectivity = connectivity ?? getIt<IConnectivityService>();

  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  /// 取得所有留言
  @override
  List<Message> getAllMessages() {
    final messages = _localDataSource.getAll();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 依分類取得留言
  @override
  List<Message> getMessagesByCategory(String category) {
    final messages = _localDataSource.getAll().where((m) => m.category == category).toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 取得主留言 (非回覆)
  @override
  List<Message> getMainMessages({String? category}) {
    var messages = _localDataSource.getAll().where((m) => m.parentId == null);

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
    final messages = _localDataSource.getAll().where((m) => m.parentId == parentUuid).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// 依 UUID 取得留言
  @override
  Message? getByUuid(String uuid) {
    return _localDataSource.getByUuid(uuid);
  }

  /// 新增留言
  @override
  Future<void> addMessage(Message message) async {
    await _localDataSource.add(message);
    // TODO: Trigger Sync or queue?
  }

  /// 刪除留言 (依 UUID)
  @override
  Future<void> deleteByUuid(String uuid) async {
    final item = _localDataSource.getByUuid(uuid);
    if (item != null) {
      // Hive key access if Message extends HiveObject and is attached
      if (item.isInBox) {
        await item.delete();
      } else {
        // Fallback if not attached (shouldn't happen if retrieved from box)
        // But MessageLocalDataSource.getByUuid matches filters filter?
        // No, getByUuid uses firstWhere.
        // LocalDataSource.delete takes key.
        // I need key.
        // item.key works if in box.
        await _localDataSource.delete(item.key);
      }
    }
  }

  /// 批次同步留言 (從雲端) - 完全覆蓋模式 (Legacy/Optimization)
  @override
  Future<void> syncFromCloud(List<Message> cloudMessages) async {
    // 清除現有資料，用雲端資料完全覆蓋
    await _localDataSource.clear();

    // 寫入雲端資料
    for (final msg in cloudMessages) {
      await _localDataSource.add(msg);
    }
    await saveLastSyncTime(DateTime.now());
  }

  /// Sync Implementation (Autonomous)
  Future<void> sync(String tripId) async {
    if (_connectivity.isOffline) {
      LogService.warning('Offline mode, skipping message sync', source: _source);
      return;
    }

    try {
      LogService.info('Syncing messages for trip: $tripId', source: _source);
      final cloudMessages = await _remoteDataSource.fetchMessages(tripId);
      await syncFromCloud(cloudMessages);
      LogService.info('Sync messages complete', source: _source);
    } catch (e) {
      LogService.error('Sync messages failed: $e', source: _source);
      rethrow;
    }
  }

  /// 取得待上傳的本地留言 (尚未在雲端)
  @override
  List<Message> getPendingMessages(Set<String> cloudUuids) {
    return _localDataSource.getAll().where((m) => !cloudUuids.contains(m.uuid)).toList();
  }

  /// 監聽留言變更
  @override
  Stream<BoxEvent> watchAllMessages() {
    return _localDataSource.watch();
  }

  /// 儲存最後同步時間
  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    await _localDataSource.saveLastSyncTime(time);
  }

  /// 取得最後同步時間
  @override
  DateTime? getLastSyncTime() {
    return _localDataSource.getLastSyncTime();
  }

  /// 清除所有留言 (Debug 用途)
  @override
  Future<void> clearAll() async {
    await _localDataSource.clear();
  }
}
