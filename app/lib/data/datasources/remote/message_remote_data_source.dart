import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';
import '../../api/mappers/message_api_mapper.dart';
import '../../api/services/message_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_message_remote_data_source.dart';
import '../../../core/error/result.dart';

/// 留言 (Message) 的遠端資料來源實作
@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSource implements IMessageRemoteDataSource {
  static const String _source = 'MessageRemoteDataSource';

  final MessageApiService _messageApi;

  MessageRemoteDataSource(this._messageApi);

  @override
  Future<Result<PaginatedList<Message>, Exception>> getMessages(String tripId, {int? page, int? limit}) async {
    try {
      LogService.info('獲取行程留言列表: $tripId (page: $page, limit: $limit)...', source: _source);
      final response = await _messageApi.listTripMessages(tripId, page: page, limit: limit);
      final messages = response.items.map((r) => MessageApiMapper.fromResponse(r)).toList();
      return Success(
        PaginatedList<Message>(
          items: messages,
          page: response.pagination.page,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ),
      );
    } catch (e) {
      LogService.error('獲取留言失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> addMessage({
    required String tripId,
    required String content,
    String? replyToId,
  }) async {
    try {
      LogService.info('新增行程留言: $tripId - $content', source: _source);
      final request = MessageApiMapper.toCreateRequest(content, replyToId);
      final response = await _messageApi.addMessage(tripId, request);
      return Success(response.id);
    } catch (e) {
      LogService.error('新增留言失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteMessage(String tripId, String messageId) async {
    try {
      LogService.info('刪除行程留言: trip $tripId, msg $messageId', source: _source);
      await _messageApi.deleteMessage(tripId, messageId);
      return const Success(null);
    } catch (e) {
      LogService.error('刪除留言失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
