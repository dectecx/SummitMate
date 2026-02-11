import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/itinerary_item.dart';
import '../../../infrastructure/clients/gas_api_client.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_itinerary_remote_data_source.dart';

/// 行程項目 (ItineraryItem) 的遠端資料來源實作
class ItineraryRemoteDataSource implements IItineraryRemoteDataSource {
  static const String _source = 'ItineraryRemoteDataSource';

  final NetworkAwareClient _apiClient;

  ItineraryRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得雲端行程節點列表
  ///
  /// [tripId] 指定的行程 ID
  @override
  Future<List<ItineraryItem>> getItinerary(String tripId) async {
    try {
      LogService.info('Fetching itinerary for trip: $tripId', source: _source);

      // 設定 API 參數
      final queryParams = <String, String>{'action': ApiConfig.actionTripGetFull, 'trip_id': tripId};

      // 發送 GET 請求
      final response = await _apiClient.get('', queryParameters: queryParams);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // 解析回應
      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }

      // 轉換資料為 ItineraryItem 列表
      final itineraryList =
          (gasResponse.data['itinerary'] as List<dynamic>?)
              ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.debug('Fetched ${itineraryList.length} itinerary items', source: _source);
      return itineraryList;
    } catch (e) {
      LogService.error('FetchItinerary failed: $e', source: _source);
      rethrow;
    }
  }
}
