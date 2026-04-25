import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/message.dart';
import '../interfaces/i_message_repository.dart';

/// 模擬行程留言板 Repository
class MockMessageRepository implements IMessageRepository {
  final List<Message> _mockMessages = [];

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  List<Message> getByTripId(String tripId) {
    return _mockMessages.where((m) => m.tripId == tripId).toList();
  }

  @override
  Future<Result<PaginatedList<Message>, Exception>> getRemoteMessages(String tripId, {int? page, int? limit}) async {
    return Success(PaginatedList(items: _mockMessages, page: page ?? 1, total: _mockMessages.length, hasMore: false));
  }

  @override
  Future<Result<void, Exception>> saveLocally(Message message) async {
    _mockMessages.add(message);
    return const Success(null);
  }

  @override
  Future<Result<String, Exception>> addMessage({
    required String tripId,
    required String content,
    String? replyToId,
  }) async {
    return const Success('mock-msg-id');
  }

  @override
  Future<Result<void, Exception>> deleteById(String tripId, String messageId) async {
    _mockMessages.removeWhere((m) => m.id == messageId);
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async {
    _mockMessages.removeWhere((m) => m.tripId == tripId);
    return const Success(null);
  }
}
