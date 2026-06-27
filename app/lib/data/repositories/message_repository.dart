import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_message_local_data_source.dart';
import '../datasources/interfaces/i_message_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'base/repository_remote_access.dart';

/// 行程留言板 Repository 實作（B 模式：讀快取／寫線上）
///
/// 讀取回傳本地快取；[getRemoteMessages] 與寫入（[addMessage]/[deleteById]）
/// 經 [RepositoryRemoteAccess.online] 守門（離線→`OfflineException`），
/// 成功後更新本地快取。
@LazySingleton(as: IMessageRepository)
class MessageRepository with RepositoryRemoteAccess implements IMessageRepository {
  final IMessageLocalDataSource _local;
  final IMessageRemoteDataSource _remote;

  @override
  final IConnectivityService connectivity;

  MessageRepository(this._local, this._remote, this.connectivity);

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  @override
  Future<List<Message>> getByTripId(String tripId) async {
    final messages = await _local.getAll();
    return messages.where((m) => m.tripId == tripId).toList();
  }

  @override
  Future<Result<PaginatedList<Message>, Exception>> getRemoteMessages(String tripId, {int? page, int? limit}) {
    return online(
      'getMessages',
      () => _remote.getMessages(tripId, page: page, limit: limit),
      cache: (paginated) async {
        for (final entity in paginated.items) {
          await _local.add(entity);
        }
      },
    );
  }

  @override
  Future<Result<void, Exception>> saveLocally(Message message) async {
    await _local.add(message);
    return const Success(null);
  }

  @override
  Future<Result<String, Exception>> addMessage({
    required String tripId,
    required String content,
    String? replyToId,
  }) {
    return online('addMessage', () => _remote.addMessage(tripId: tripId, content: content, replyToId: replyToId));
  }

  @override
  Future<Result<void, Exception>> deleteById(String tripId, String messageId) {
    return online(
      'deleteMessage',
      () => _remote.deleteMessage(tripId, messageId),
      cache: (_) => _local.deleteById(messageId),
    );
  }

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async {
    final messages = await _local.getAll();
    for (final item in messages.where((m) => m.tripId == tripId)) {
      await _local.deleteById(item.id);
    }
    return const Success(null);
  }
}
