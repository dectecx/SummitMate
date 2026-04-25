import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../api/models/trip_api_models.dart';
import '../../api/services/trip_api_service.dart';
import '../../api/services/user_api_service.dart';
import '../../api/mappers/trip_api_mapper.dart';
import '../../api/mappers/user_api_mapper.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_remote_data_source.dart';

/// 行程 (Trip) 的遠端資料來源實作
@LazySingleton(as: ITripRemoteDataSource)
class TripRemoteDataSource implements ITripRemoteDataSource {
  static const String _source = 'TripRemoteDataSource';

  final TripApiService _tripApi;
  final UserApiService _userApi;

  TripRemoteDataSource(this._tripApi, this._userApi);

  @override
  Future<PaginatedList<Trip>> getTrips({String? cursor, int? limit, String? search}) async {
    try {
      LogService.info('取得雲端行程列表 (cursor: $cursor, limit: $limit, search: $search)...', source: _source);
      final response = await _tripApi.listTrips(cursor: cursor, limit: limit, search: search);
      return PaginatedList<Trip>(
        items: response.items.map(TripApiMapper.fromListItemResponse).toList(),
        nextCursor: response.pagination.nextCursor,
        hasMore: response.pagination.hasMore,
      );
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
      await _tripApi.updateMemberRole(tripId, userId, UpdateMemberRoleRequest(role: role));
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
      // 透過 UserApiService 查詢 email
      final userResponse = await _userApi.getUserById(userId);
      final email = userResponse.email;

      // 呼叫現有的 addMemberByEmail (內部使用 _tripApi.addMember)
      await addMemberByEmail(tripId, email, role: role);
    } catch (e) {
      LogService.error('Remote AddMemberById failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> searchUserByEmail(String email) async {
    try {
      LogService.info('Searching user by email: $email', source: _source);
      final response = await _userApi.searchUserByEmail(email);
      return UserApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('Remote SearchUserByEmail failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> searchUserById(String userId) async {
    try {
      LogService.info('Searching user by ID: $userId', source: _source);
      final response = await _userApi.getUserById(userId);
      return UserApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('Remote SearchUserById failed: $e', source: _source);
      rethrow;
    }
  }
}
