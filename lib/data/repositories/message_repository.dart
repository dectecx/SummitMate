import '../../core/di.dart';
import '../../core/error/result.dart';
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
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取得所有留言 (依時間倒序)
  @override
  Future<Result<List<Message>, Exception>> getAllMessages() async {
    try {
      final messages = _localDataSource.getAll();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Success(messages);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 依分類取得留言
  ///
  /// [category] 留言分類 (e.g., "Gear")
  @override
  Future<Result<List<Message>, Exception>> getMessagesByCategory(String category) async {
    try {
      final messages = _localDataSource.getAll().where((m) => m.category == category).toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Success(messages);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取得主留言 (非回覆)
  ///
  /// [category] 選擇性篩選分類
  @override
  Future<Result<List<Message>, Exception>> getMainMessages({String? category}) async {
    try {
      var messages = _localDataSource.getAll().where((m) => m.parentId == null);

      if (category != null) {
        messages = messages.where((m) => m.category == category);
      }

      final result = messages.toList();
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Success(result);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取得指定留言的回覆列表
  ///
  /// [parentId] 父留言的 ID
  @override
  Future<Result<List<Message>, Exception>> getReplies(String parentId) async {
    try {
      final messages = _localDataSource.getAll().where((m) => m.parentId == parentId).toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return Success(messages);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 依 ID 取得留言
  ///
  /// [id] 留言 ID
  @override
  Future<Result<Message?, Exception>> getById(String id) async {
    try {
      return Success(_localDataSource.getById(id));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 新增留言
  ///
  /// [message] 欲新增的留言物件
  @override
  Future<Result<void, Exception>> addMessage(Message message) async {
    try {
      await _localDataSource.add(message);
      // TODO: Trigger Sync or queue?
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 刪除留言 (依 ID)
  ///
  /// [id] 欲刪除的留言 ID
  @override
  Future<Result<void, Exception>> deleteById(String id) async {
    try {
      final item = _localDataSource.getById(id);
      if (item != null) {
        if (item.isInBox) {
          await item.delete();
        } else {
          await _localDataSource.delete(item.key);
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 批次同步留言 (從雲端) - 完全覆蓋模式 (Legacy/Optimization)
  ///
  /// [cloudMessages] 雲端下載的留言列表
  @override
  Future<Result<void, Exception>> syncFromCloud(List<Message> cloudMessages) async {
    try {
      await _localDataSource.clear();
      for (final msg in cloudMessages) {
        await _localDataSource.add(msg);
      }
      await saveLastSyncTime(DateTime.now());
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 自動同步 (自主判斷連線狀態)
  ///
  /// [tripId] 當前行程 ID
  @override
  Future<Result<void, Exception>> sync(String tripId) async {
    if (_connectivity.isOffline) {
      LogService.warning('Offline mode, skipping message sync', source: _source);
      return const Success(null);
    }

    try {
      LogService.info('Syncing messages for trip: $tripId', source: _source);
      final cloudMessages = await _remoteDataSource.getMessages(tripId);
      final result = await syncFromCloud(cloudMessages);
      if (result is Failure) throw result.exception;
      LogService.info('Sync messages complete', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('Sync messages failed: $e', source: _source);
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取得待上傳的本地留言 (尚未在雲端)
  ///
  /// [cloudIds] 已存在於雲端的 ID 集合
  @override
  Future<Result<List<Message>, Exception>> getPendingMessages(Set<String> cloudIds) async {
    try {
      return Success(_localDataSource.getAll().where((m) => !cloudIds.contains(m.id)).toList());
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 監聽留言變更
  @override
  Stream<BoxEvent> watchAllMessages() {
    return _localDataSource.watch();
  }

  /// 儲存最後同步時間
  @override
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time) async {
    try {
      await _localDataSource.saveLastSyncTime(time);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取得最後同步時間
  @override
  Future<Result<DateTime?, Exception>> getLastSyncTime() async {
    try {
      return Success(_localDataSource.getLastSyncTime());
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 清除所有留言 (Debug 用途)
  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
