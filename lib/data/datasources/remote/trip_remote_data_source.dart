import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/trip.dart';
import '../../../infrastructure/clients/gas_api_client.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_remote_data_source.dart';

/// 行程 (Trip) 的遠端資料來源實作
class TripRemoteDataSource implements ITripRemoteDataSource {
  static const String _source = 'TripRemoteDataSource';

  final NetworkAwareClient _apiClient;

  TripRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得雲端行程列表
  @override
  Future<List<Trip>> getTrips() async {
    try {
      LogService.info('取得雲端行程列表...', source: _source);
      final response = await _apiClient.post({'action': ApiConfig.actionTripList});

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw Exception(gasResponse.message);
      }

      final trips =
          (gasResponse.data['trips'] as List<dynamic>?)
              ?.map((item) => Trip.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return trips;
    } catch (e) {
      LogService.error('Remote GetTrips failed: $e', source: _source);
      rethrow;
    }
  }

  /// 上傳新行程
  ///
  /// 回傳新建立的行程 ID
  @override
  Future<String> uploadTrip(Trip trip) async {
    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionTripCreate,
        'id': trip.id,
        'name': trip.name,
        'start_date': trip.startDate.toIso8601String(),
        'end_date': trip.endDate?.toIso8601String() ?? '',
        'description': trip.description ?? '',
        'cover_image': trip.coverImage ?? '',
        'is_active': trip.isActive,
      });

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

      return gasResponse.data['id'] as String? ?? trip.id;
    } catch (e) {
      LogService.error('Remote UploadTrip failed: $e', source: _source);
      rethrow;
    }
  }

  /// 更新雲端行程資料
  @override
  Future<void> updateTrip(Trip trip) async {
    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionTripUpdate,
        'id': trip.id,
        'name': trip.name,
        'start_date': trip.startDate.toIso8601String(),
        'end_date': trip.endDate?.toIso8601String() ?? '',
        'description': trip.description ?? '',
        'cover_image': trip.coverImage ?? '',
        'is_active': trip.isActive,
      });

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
    } catch (e) {
      LogService.error('Remote UpdateTrip failed: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除雲端行程
  ///
  /// [tripId] 目標行程 ID
  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionTripDelete,
        'trip_id': tripId,
      }); // Note: API expects trip_id

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) throw Exception(gasResponse.message);
    } catch (e) {
      LogService.error('Remote DeleteTrip failed: $e', source: _source);
      rethrow;
    }
  }

  /// 完整同步行程 (包含行程、細節、裝備等)
  ///
  /// 用於一鍵備份或同步
  @override
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async {
    try {
      // Assuming items are already appropriate objects or Maps
      final itineraryJson = itineraryItems.map((e) => e.toJson()).toList();
      final gearJson = gearItems.map((e) => e.toJson()).toList();
      final tripJson = trip.toJson();

      final response = await _apiClient.post({
        'action': ApiConfig.actionTripSync,
        'trip': tripJson,
        'itinerary': itineraryJson,
        'gear': gearJson,
      });

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) throw Exception(gasResponse.message);

      return trip.id;
    } catch (e) {
      LogService.error('Remote UploadFullTrip failed: $e', source: _source);
      rethrow;
    }
  }
}
