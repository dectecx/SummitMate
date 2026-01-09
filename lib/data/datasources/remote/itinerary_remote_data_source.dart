import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/itinerary_item.dart';
import '../../../services/gas_api_client.dart';
import '../../../services/network_aware_client.dart';
import '../../../services/log_service.dart';
import '../interfaces/i_itinerary_remote_data_source.dart';

class ItineraryRemoteDataSource implements IItineraryRemoteDataSource {
  static const String _source = 'ItineraryRemoteDataSource';

  final NetworkAwareClient _apiClient;

  ItineraryRemoteDataSource({NetworkAwareClient? apiClient})
      : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  @override
  Future<List<ItineraryItem>> fetchItinerary(String tripId) async {
    try {
      LogService.info('Fetching itinerary for trip: $tripId', source: _source);
      
      final queryParams = <String, String>{
        'action': ApiConfig.actionTripGetFull,
        'trip_id': tripId,
      };

      final response = await _apiClient.get(queryParams: queryParams);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }

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
