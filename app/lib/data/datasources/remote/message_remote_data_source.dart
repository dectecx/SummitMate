import 'package:injectable/injectable.dart';
import '../../../core/di/injection.dart';
import '../../models/message.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_message_remote_data_source.dart';

/// 留言訊息 (Message) 的遠端資料來源實作
@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSource implements IMessageRemoteDataSource {
  static const String _source = 'MessageRemoteDataSource';

  final NetworkAwareClient _apiClient;

  MessageRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  @override
  Future<List<Message>> getMessages(String tripId) async {
    try {
      LogService.info('Fetching messages for trip: $tripId', source: _source);

      final response = await _apiClient.get('/trips/$tripId/messages');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('FetchMessages failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> addMessage(Message message) async {
    try {
      final response = await _apiClient.post(
        '/trips/${message.tripId}/messages',
        data: {
          'content': message.content,
          'category': message.category,
          if (message.parentId != null) 'parent_id': message.parentId,
        },
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('AddMessage failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String tripId, String id) async {
    try {
      final response = await _apiClient.delete('/trips/$tripId/messages/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('DeleteMessage failed: $e', source: _source);
      rethrow;
    }
  }
}
