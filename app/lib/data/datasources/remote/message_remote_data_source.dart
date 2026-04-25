import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../models/message.dart';
import '../../api/services/message_api_service.dart';
import '../../api/mappers/message_api_mapper.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_message_remote_data_source.dart';

/// 留言訊息 (Message) 的遠端資料來源實作
@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSource implements IMessageRemoteDataSource {
  static const String _source = 'MessageRemoteDataSource';

  final MessageApiService _messageApi;

  MessageRemoteDataSource(Dio dio) : _messageApi = MessageApiService(dio);

  @override
  Future<List<Message>> getMessages(String tripId) async {
    try {
      LogService.info('Fetching messages for trip: $tripId', source: _source);
      final responses = await _messageApi.listMessages(tripId);
      return responses.map(MessageApiMapper.fromResponse).toList();
    } catch (e) {
      LogService.error('FetchMessages failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> addMessage(Message message) async {
    try {
      final request = MessageApiMapper.toCreateRequest(message);
      await _messageApi.addMessage(message.tripId ?? '', request);
      LogService.info('AddMessage success', source: _source);
    } catch (e) {
      LogService.error('AddMessage failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String tripId, String id) async {
    try {
      await _messageApi.deleteMessage(tripId, id);
      LogService.info('DeleteMessage success: $id', source: _source);
    } catch (e) {
      LogService.error('DeleteMessage failed: $e', source: _source);
      rethrow;
    }
  }
}
