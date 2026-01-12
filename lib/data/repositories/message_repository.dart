import '../../core/di.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../../infrastructure/tools/log_service.dart';
import '../models/message.dart';
import 'interfaces/i_message_repository.dart';
import '../datasources/interfaces/i_message_local_data_source.dart';
import '../datasources/interfaces/i_message_remote_data_source.dart';
import 'package:hive/hive.dart';

/// 留言 Repository
///
/// 協調本地資料庫 (Hive) 與遠端資料來源 (API)，負責留言資料的 CRUD 與同步。
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

  /// 初始化 Repository (主要是本地資料庫)
  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  /// 取得所有留言 (依時間倒序)
  @override
  List<Message> getAllMessages() {
    final messages = _localDataSource.getAll();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 依分類取得留言
  ///
  /// [category] 留言分類 (e.g., "Gear")
  @override
  List<Message> getMessagesByCategory(String category) {
    final messages = _localDataSource.getAll().where((m) => m.category == category).toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  /// 取得主留言 (非回覆)
  ///
  /// [category] 選擇性篩選分類
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

  /// 取得指定留言的回覆列表
  ///
  /// [parentId] 父留言的 ID
  @override
  List<Message> getReplies(String parentId) {
    final messages = _localDataSource.getAll().where((m) => m.parentId == parentId).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// 依 ID 取得留言
  ///
  /// [id] 留言 ID
  @override
  Message? getById(String id) {
    return _localDataSource.getById(id);
  }

  /// 新增留言
  ///
  /// [message] 欲新增的留言物件
  @override
  Future<void> addMessage(Message message) async {
    await _localDataSource.add(message);
    // TODO: Trigger Sync or queue?
  }

  /// 刪除留言 (依 ID)
  ///
  /// [id] 欲刪除的留言 ID
  @override
  Future<void> deleteById(String id) async {
    final item = _localDataSource.getById(id);
    if (item != null) {
      // 若已載入 HiveObject，直接 delete
      if (item.isInBox) {
        await item.delete();
      } else {
        // 否則透過 LocalDataSource 刪除 (需知道 key)
        await _localDataSource.delete(item.key);
      }
    }
  }

  /// 批次同步留言 (從雲端) - 完全覆蓋模式 (Legacy/Optimization)
  ///
  /// [cloudMessages] 雲端下載的留言列表
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

  /// 自動同步 (自主判斷連線狀態)
  ///
  /// [tripId] 當前行程 ID
  @override
  Future<void> sync(String tripId) async {
    if (_connectivity.isOffline) {
      LogService.warning('Offline mode, skipping message sync', source: _source);
      return;
    }

    try {
      LogService.info('Syncing messages for trip: $tripId', source: _source);
      final cloudMessages = await _remoteDataSource.getMessages(tripId);
      await syncFromCloud(cloudMessages);
      LogService.info('Sync messages complete', source: _source);
    } catch (e) {
      LogService.error('Sync messages failed: $e', source: _source);
      rethrow;
    }
  }

  /// 取得待上傳的本地留言 (尚未在雲端)
  ///
  /// [cloudIds] 已存在於雲端的 ID 集合
  @override
  List<Message> getPendingMessages(Set<String> cloudIds) {
    return _localDataSource.getAll().where((m) => !cloudIds.contains(m.id)).toList();
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
