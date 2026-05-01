import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_message_local_data_source.dart';
import '../datasources/interfaces/i_message_remote_data_source.dart';
import '../models/message_model.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../infrastructure/tools/log_service.dart';

/// 行程留言板 Repository (支援 Offline-First)
@LazySingleton(as: IMessageRepository)
class MessageRepository implements IMessageRepository {
  static const String _source = 'MessageRepository';

  final IMessageLocalDataSource _localDataSource;
  final IMessageRemoteDataSource _remoteDataSource;

  MessageRepository(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  List<Message> getByTripId(String tripId) {
    return _localDataSource
        .getAll()
        .where((m) => m.tripId == tripId)
        .map((m) => m.toDomain())
        .toList();
  }

  @override
  Future<Result<PaginatedList<Message>, Exception>> getRemoteMessages(
    String tripId, {
    int? page,
    int? limit,
  }) async {
    final result = await _remoteDataSource.getMessages(tripId, page: page, limit: limit);
    if (result is Success<PaginatedList<MessageModel>, Exception>) {
      // 緩存到本地
      for (final model in result.value.items) {
        await _localDataSource.add(model);
      }
      
      // 轉換為 Domain Entity
      final domainItems = result.value.items.map((m) => m.toDomain()).toList();
      return Success(
        PaginatedList<Message>(
          items: domainItems,
          page: result.value.page,
          total: result.value.total,
          hasMore: result.value.hasMore,
        ),
      );
    }
    return Failure((result as Failure).exception);
  }

  @override
  Future<Result<void, Exception>> saveLocally(Message message) async {
    await _localDataSource.add(MessageModel.fromDomain(message));
    return const Success(null);
  }

  @override
  Future<Result<String, Exception>> addMessage({
    required String tripId,
    required String content,
    String? replyToId,
  }) async {
    // 遠端新增
    final result = await _remoteDataSource.addMessage(tripId: tripId, content: content, replyToId: replyToId);

    if (result is Success<String, Exception>) {
      // 如果成功，觸發重新獲取最新留言以同步本地資料
      await getRemoteMessages(tripId);
    }

    return result;
  }

  @override
  Future<Result<void, Exception>> deleteById(String tripId, String messageId) async {
    // 1. 本地先刪除
    await _localDataSource.delete(messageId);

    // 2. 嘗試同步到遠端
    try {
      await _remoteDataSource.deleteMessage(tripId, messageId);
      LogService.info('Auto-sync delete message success: $messageId', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.warning('Auto-sync message failed: $e', source: _source);
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async {
    final itemsToDelete = _localDataSource.getAll().where((m) => m.tripId == tripId);
    for (final item in itemsToDelete) {
      await _localDataSource.delete(item.id);
    }
    return const Success(null);
  }
}
