import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/message.dart';
import '../../../services/gas_api_client.dart';
import '../../../services/network_aware_client.dart';
import '../../../services/log_service.dart';
import '../interfaces/i_message_remote_data_source.dart';

class MessageRemoteDataSource implements IMessageRemoteDataSource {
  static const String _source = 'MessageRemoteDataSource';

  final NetworkAwareClient _apiClient;

  MessageRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

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
}
