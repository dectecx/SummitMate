import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_message_local_data_source.dart';
import '../datasources/interfaces/i_message_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../infrastructure/tools/log_service.dart';

/// 行程留言板 Repository 實作
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
  Future<List<Message>> getByTripId(String tripId) async {
    final messages = await _localDataSource.getAll();
    return messages.where((m) => m.tripId == tripId).toList();
  }

  @override
  Future<Result<PaginatedList<Message>, Exception>> getRemoteMessages(String tripId, {int? page, int? limit}) async {
    try {
      final result = await _remoteDataSource.getMessages(tripId, page: page, limit: limit);
      if (result is Success<PaginatedList<Message>, Exception>) {
        for (final entity in result.value.items) {
          await _localDataSource.add(entity);
        }
        return result;
      }
      return Failure((result as Failure).exception);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> saveLocally(Message message) async {
    await _localDataSource.add(message);
    return const Success(null);
  }

  @override
  Future<Result<String, Exception>> addMessage({
    required String tripId,
    required String content,
    String? replyToId,
  }) async {
    final result = await _remoteDataSource.addMessage(tripId: tripId, content: content, replyToId: replyToId);
    if (result is Success<String, Exception>) {
      // 成功後嘗試背景更新本地資料
      getRemoteMessages(tripId);
    }
    return result;
  }

  @override
  Future<Result<void, Exception>> deleteById(String tripId, String messageId) async {
    await _localDataSource.deleteById(messageId);
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
    final messages = await _localDataSource.getAll();
    final itemsToDelete = messages.where((m) => m.tripId == tripId);
    for (final item in itemsToDelete) {
      await _localDataSource.deleteById(item.id);
    }
    return const Success(null);
  }
}
