import '../../data/models/trip.dart';

/// 行程雲端操作結果
class TripCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const TripCloudResult._({required this.isSuccess, this.data, this.errorMessage});

  factory TripCloudResult.success(T? data) => TripCloudResult._(isSuccess: true, data: data);
  factory TripCloudResult.failure(String message) => TripCloudResult._(isSuccess: false, errorMessage: message);
}

/// 行程雲端服務介面
/// 負責行程資料的雲端同步與管理
abstract interface class ITripCloudService {
  /// 取得所有雲端行程
  Future<TripCloudResult<List<Trip>>> getTrips();

  /// 上傳行程到雲端
  Future<TripCloudResult<String>> uploadTrip(Trip trip);

  /// 完整上傳行程 (包含行程表與裝備)
  Future<TripCloudResult<String>> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  });

  /// 更新雲端行程
  Future<TripCloudResult<void>> updateTrip(Trip trip);

  /// 刪除雲端行程
  Future<TripCloudResult<void>> deleteTrip(String tripId);
}
