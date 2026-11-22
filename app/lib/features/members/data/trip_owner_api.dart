import 'package:dio/dio.dart';

import '../../../core/auth/auth_api.dart';

/// Handing a trip to another member. Online only: ownership is never decided by offline edits.
abstract interface class TripOwnerApi {
  Future<void> transfer(String tripId, String newOwnerId);
}

class DioTripOwnerApi implements TripOwnerApi {
  DioTripOwnerApi(this._dio);
  final Dio _dio;

  @override
  Future<void> transfer(String tripId, String newOwnerId) async {
    try {
      await _dio.post<void>('/trips/$tripId/transfer-owner', data: {'user_id': newOwnerId});
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw AuthNetworkException(e.type.name);
      final data = res.data;
      throw AuthException(
        status: res.statusCode ?? 0,
        code: data is Map && data['code'] is String ? data['code'] as String : 'http_${res.statusCode}',
        message: data is Map && data['message'] is String ? data['message'] as String : '',
      );
    }
  }
}
