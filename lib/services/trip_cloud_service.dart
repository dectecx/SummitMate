import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/trip.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// 行程雲端同步服務
class TripCloudService {
  static const String _source = 'TripCloud';

  final GasApiClient _apiClient;

  TripCloudService({GasApiClient? apiClient}) : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.gasBaseUrl);

  /// 取得所有雲端行程
  Future<TripCloudResult<List<Trip>>> fetchTrips() async {
    try {
      LogService.info('取得雲端行程列表...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionFetchTrips});

      if (response.statusCode != 200) {
        return TripCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJsonString(response.body);
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

      final gasResponse = GasApiResponse.fromJsonString(response.body);
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

      final gasResponse = GasApiResponse.fromJsonString(response.body);
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

      final gasResponse = GasApiResponse.fromJsonString(response.body);
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
