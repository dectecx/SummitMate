import '../core/constants.dart';
import '../core/di.dart';
import '../data/models/trip.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// 行程雲端同步服務
class TripCloudService {
  static const String _source = 'TripCloud';

  final GasApiClient _apiClient;

  TripCloudService({GasApiClient? apiClient}) : _apiClient = apiClient ?? getIt<GasApiClient>();

  /// 取得所有雲端行程
  Future<TripCloudResult<List<Trip>>> fetchTrips() async {
    try {
      LogService.info('取得雲端行程列表...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionFetchTrips});

      if (response.statusCode != 200) {
        return TripCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return TripCloudResult.failure(gasResponse.message);
      }

      final trips =
          (gasResponse.data['trips'] as List<dynamic>?)
              ?.map((item) => Trip.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.info('取得 ${trips.length} 個雲端行程', source: _source);
      return TripCloudResult.success(trips);
    } catch (e) {
      LogService.error('取得雲端行程失敗: $e', source: _source);
      return TripCloudResult.failure('$e');
    }
  }

  /// 上傳行程到雲端
  Future<TripCloudResult<String>> uploadTrip(Trip trip) async {
    try {
      LogService.info('上傳行程: ${trip.name}', source: _source);

      final response = await _apiClient.post({
        'action': ApiConfig.actionAddTrip,
        'id': trip.id,
        'name': trip.name,
        'start_date': trip.startDate.toIso8601String(),
        'end_date': trip.endDate?.toIso8601String() ?? '',
        'description': trip.description ?? '',
        'cover_image': trip.coverImage ?? '',
        'is_active': trip.isActive,
      });

      if (response.statusCode != 200) {
        return TripCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return TripCloudResult.failure(gasResponse.message);
      }

      final tripId = gasResponse.data['id'] as String? ?? trip.id;
      LogService.info('上傳成功: $tripId', source: _source);
      return TripCloudResult.success(tripId);
    } catch (e) {
      LogService.error('上傳行程失敗: $e', source: _source);
      return TripCloudResult.failure('$e');
    }
  }

  /// 完整上傳行程 (包含行程表與裝備)
  ///
  /// 使用 `sync_trip_full` 動作
  Future<TripCloudResult<String>> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async {
    try {
      LogService.info('完整上傳行程: ${trip.name} (含 ${itineraryItems.length} 行程, ${gearItems.length} 裝備)', source: _source);

      // 建構完整 Payload
      // 注意: List內的物件應已是 toJson() 後的 Map 或其模型物件 (若 apiClient 支援 msgpack/json encode)
      // 這裡假設傳入的是 Model List，需轉為 Json List
      final itineraryJson = itineraryItems.map((e) => e.toJson()).toList();
      final gearJson = gearItems.map((e) => e.toJson()).toList();
      final tripJson = trip.toJson();

      final response = await _apiClient.post({
        'action': 'sync_trip_full',
        'trip': tripJson,
        'itinerary': itineraryJson,
        'gear': gearJson,
      });

      if (response.statusCode != 200) {
        return TripCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return TripCloudResult.failure(gasResponse.message);
      }

      LogService.info('完整上傳成功', source: _source);
      return TripCloudResult.success(trip.id);
    } catch (e) {
      LogService.error('完整上傳行程失敗: $e', source: _source);
      return TripCloudResult.failure('$e');
    }
  }

  /// 更新雲端行程
  Future<TripCloudResult<void>> updateTrip(Trip trip) async {
    try {
      LogService.info('更新行程: ${trip.name}', source: _source);

      final response = await _apiClient.post({
        'action': ApiConfig.actionUpdateTrip,
        'id': trip.id,
        'name': trip.name,
        'start_date': trip.startDate.toIso8601String(),
        'end_date': trip.endDate?.toIso8601String() ?? '',
        'description': trip.description ?? '',
        'cover_image': trip.coverImage ?? '',
        'is_active': trip.isActive,
      });

      if (response.statusCode != 200) {
        return TripCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return TripCloudResult.failure(gasResponse.message);
      }

      LogService.info('更新成功', source: _source);
      return TripCloudResult.success(null);
    } catch (e) {
      LogService.error('更新行程失敗: $e', source: _source);
      return TripCloudResult.failure('$e');
    }
  }

  /// 刪除雲端行程
  Future<TripCloudResult<void>> deleteTrip(String tripId) async {
    try {
      LogService.info('刪除行程: $tripId', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionDeleteTrip, 'trip_id': tripId});

      if (response.statusCode != 200) {
        return TripCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return TripCloudResult.failure(gasResponse.message);
      }

      LogService.info('刪除成功', source: _source);
      return TripCloudResult.success(null);
    } catch (e) {
      LogService.error('刪除行程失敗: $e', source: _source);
      return TripCloudResult.failure('$e');
    }
  }
}

/// 行程雲端操作結果
class TripCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  TripCloudResult._({required this.isSuccess, this.data, this.errorMessage});

  factory TripCloudResult.success(T? data) => TripCloudResult._(isSuccess: true, data: data);
  factory TripCloudResult.failure(String message) => TripCloudResult._(isSuccess: false, errorMessage: message);
}
