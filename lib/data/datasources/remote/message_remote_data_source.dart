import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/message.dart';
import '../../../infrastructure/clients/gas_api_client.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_message_remote_data_source.dart';

/// 留言訊息 (Message) 的遠端資料來源實作
class MessageRemoteDataSource implements IMessageRemoteDataSource {
  static const String _source = 'MessageRemoteDataSource';

  final NetworkAwareClient _apiClient;

  MessageRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得行程的所有留言
  ///
  /// [tripId] 指定的行程 ID
  @override
  Future<List<Message>> getMessages(String tripId) async {
    try {
      LogService.info('Fetching messages for trip: $tripId', source: _source);

      final queryParams = <String, String>{'action': ApiConfig.actionTripGetFull, 'trip_id': tripId};

      final response = await _apiClient.get(queryParams: queryParams);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }

      final messageList =
          (gasResponse.data['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.debug('Fetched ${messageList.length} messages', source: _source);
      return messageList;
    } catch (e) {
      LogService.error('FetchMessages failed: $e', source: _source);
      rethrow;
    }
  }

  /// 新增留言
  ///
  /// [message] 欲新增的留言物件
  @override
  Future<void> addMessage(Message message) async {
    try {
      final response = await _apiClient.post({'action': ApiConfig.actionMessageCreate, 'data': message.toJson()});

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
    } catch (e) {
      LogService.error('AddMessage failed: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除留言
  ///
  /// [id] 留言 ID
  @override
  Future<void> deleteMessage(String id) async {
    try {
      final response = await _apiClient.post({'action': ApiConfig.actionMessageDelete, 'id': id});

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }
    } catch (e) {
      LogService.error('DeleteMessage failed: $e', source: _source);
      rethrow;
    }
  }
}
