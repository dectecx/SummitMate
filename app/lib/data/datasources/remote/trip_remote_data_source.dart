import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../api/models/trip_api_models.dart';
import '../../api/services/trip_api_service.dart';
import '../../api/mappers/trip_api_mapper.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_remote_data_source.dart';

/// 行程 (Trip) 的遠端資料來源實作
@LazySingleton(as: ITripRemoteDataSource)
class TripRemoteDataSource implements ITripRemoteDataSource {
  static const String _source = 'TripRemoteDataSource';

  final TripApiService _tripApi;
  final Dio _dio;

  TripRemoteDataSource(this._tripApi, this._dio);

  @override
  Future<List<Trip>> getTrips() async {
    try {
      LogService.info('取得雲端行程列表...', source: _source);
      final responses = await _tripApi.listTrips();
      return responses.map(TripApiMapper.fromResponse).toList();
    } catch (e) {
      LogService.error('Remote GetTrips failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<String> uploadTrip(Trip trip) async {
    try {
      final request = TripApiMapper.toCreateRequest(trip);
      final response = await _tripApi.createTrip(request);
      LogService.info('Remote UploadTrip success: ${response.id}', source: _source);
      return response.id;
    } catch (e) {
      LogService.error('Remote UploadTrip failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    try {
      final request = TripApiMapper.toUpdateRequest(trip);
      await _tripApi.updateTrip(trip.id, request);
      LogService.info('Remote UpdateTrip success: ${trip.id}', source: _source);
    } catch (e) {
      LogService.error('Remote UpdateTrip failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripApi.deleteTrip(tripId);
      LogService.info('Remote DeleteTrip success: $tripId', source: _source);
    } catch (e) {
      LogService.error('Remote DeleteTrip failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    try {
      final members = await _tripApi.getMembers(tripId);
      return members.map((m) => m.toJson()).toList();
    } catch (e) {
      LogService.error('Remote GetTripMembers failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> updateMemberRole(String tripId, String userId, String role) async {
    try {
      await _tripApi.updateMemberRole(
        tripId,
        userId,
        UpdateMemberRoleRequest(role: role),
      );
    } catch (e) {
      LogService.error('Remote UpdateMemberRole failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> removeMember(String tripId, String userId) async {
    try {
      await _tripApi.removeMember(tripId, userId);
    } catch (e) {
      LogService.error('Remote RemoveMember failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    try {
      await _tripApi.addMember(tripId, AddMemberRequest(email: email));
    } catch (e) {
      LogService.error('Remote AddMemberByEmail failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    try {
      // TODO: 後端 AddMember API 使用 email，此處需透過 userId 查詢 email 後再呼叫
      // 暫時維持透過 Dio 直接呼叫，待 User API Service 建立後再重構
      final response = await _dio.post(
        '/trips/$tripId/members',
        data: {'user_id': userId, 'role': role},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('Remote AddMemberById failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> searchUserByEmail(String email) async {
    try {
      LogService.info('Searching user by email: $email', source: _source);
      // TODO: 待 UserApiService 建立後改用 Retrofit
      final response = await _dio.get('/users/search', queryParameters: {'email': email});
      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote SearchUserByEmail failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> searchUserById(String userId) async {
    try {
      LogService.info('Searching user by ID: $userId', source: _source);
      // TODO: 待 UserApiService 建立後改用 Retrofit
      final response = await _dio.get('/users/$userId');
      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote SearchUserById failed: $e', source: _source);
      rethrow;
    }
  }
}
