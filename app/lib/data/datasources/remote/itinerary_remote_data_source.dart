import 'package:injectable/injectable.dart';
import '../../../core/di/injection.dart';
import '../../models/itinerary_item.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_itinerary_remote_data_source.dart';

/// 行程項目 (ItineraryItem) 的遠端資料來源實作
@LazySingleton(as: IItineraryRemoteDataSource)
class ItineraryRemoteDataSource implements IItineraryRemoteDataSource {
  static const String _source = 'ItineraryRemoteDataSource';

  final NetworkAwareClient _apiClient;

  ItineraryRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得雲端行程詳細資訊
  ///
  /// [tripId] 行程 ID
  @override
  Future<List<ItineraryItem>> getItinerary(String tripId) async {
    try {
      LogService.info('獲取行程詳細資訊: $tripId', source: _source);

      final response = await _apiClient.get('/trips/$tripId');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;

      // 轉換資料為 ItineraryItem 列表
      final itineraryList =
          (data['itinerary'] as List<dynamic>?)
              ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.debug('已獲取 ${itineraryList.length} 個行程項目', source: _source);
      return itineraryList;
    } catch (e) {
      LogService.error('getItinerary 失敗: $e', source: _source);
      rethrow;
    }
  }
}
