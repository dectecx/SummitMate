import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../api/mappers/trip_api_mapper.dart';
import '../../api/services/trip_api_service.dart';
import '../../api/models/trip_api_models.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_remote_data_source.dart';
import '../../../core/error/result.dart';

/// 行程 (Trip) 的遠端資料來源實作
@LazySingleton(as: ITripRemoteDataSource)
class TripRemoteDataSource implements ITripRemoteDataSource {
  static const String _source = 'TripRemoteDataSource';

  final TripApiService _tripApi;

  TripRemoteDataSource(this._tripApi);

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getRemoteTrips({
    int? page,
    int? limit,
    String? search,
  }) async {
    try {
      LogService.info('獲取遠端行程列表 (page: $page, limit: $limit)...', source: _source);
      final response = await _tripApi.listTrips(page: page, limit: limit, search: search);
      
      final trips = response.items.map(TripApiMapper.fromListItemResponse).toList();
      
      return Success(PaginatedList<Trip>(
        items: trips,
        page: response.pagination.page,
        total: response.pagination.total,
        hasMore: response.pagination.hasMore,
      ));
    } catch (e) {
      LogService.error('獲取遠端行程失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<Trip, Exception>> getTripDetails(String tripId) async {
    try {
      final response = await _tripApi.getTrip(tripId);
      return Success(TripApiMapper.fromResponse(response));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> uploadTrip(Trip trip) async {
    try {
      LogService.info('上傳行程至遠端: ${trip.name} (${trip.id})...', source: _source);
      final request = TripApiMapper.toCreateRequest(trip);
      final response = await _tripApi.createTrip(request);
      return Success(response.id);
    } catch (e) {
      LogService.error('上傳行程失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteTrip(String id) async {
    try {
      LogService.info('刪除遠端行程: $id...', source: _source);
      await _tripApi.deleteTrip(id);
      return const Success(null);
    } catch (e) {
      LogService.error('刪除遠端行程失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId) async {
    try {
      final members = await _tripApi.getMembers(tripId);
      return Success(members.map((m) => m.toJson()).toList());
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role) async {
    try {
      await _tripApi.updateMemberRole(tripId, userId, UpdateMemberRoleRequest(role: role));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> removeMember(String tripId, String userId) async {
    try {
      await _tripApi.removeMember(tripId, userId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    try {
      await _tripApi.addMember(tripId, AddMemberRequest(email: email));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    try {
      // NOTE: Current API doesn't support addMemberById, using email for now or throw
      throw UnimplementedError('API currently only supports adding by email');
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email) async {
    try {
      throw UnimplementedError('User search by email should be in UserApiService');
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserById(String userId) async {
    try {
      throw UnimplementedError('User search by ID should be in UserApiService');
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
