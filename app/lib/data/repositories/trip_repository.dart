import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import 'interfaces/i_trip_repository.dart';

/// 行程 Repository (支援 Offline-First)
///
/// 協調 LocalDataSource (Hive) 與 RemoteDataSource (GCP) 的資料存取。
/// 處理離線快取、資料同步與成員管理。
@LazySingleton(as: ITripRepository)
class TripRepository implements ITripRepository {
  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  TripRepository(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  // ========== Data Operations ==========

  @override
  Future<Result<List<Trip>, Exception>> getAllTrips(String userId) async {
    try {
      final trips = _localDataSource.getAllTrips().where((t) => t.userId == userId).toList();
      trips.sort((a, b) => b.startDate.compareTo(a.startDate));
      return Success(trips);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<Trip?, Exception>> getActiveTrip(String userId) async {
    try {
      final trip = _localDataSource.getActiveTrip();
      return Success(trip);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<Trip?, Exception>> getTripById(String id) async {
    try {
      final trip = _localDataSource.getTripById(id);
      return Success(trip);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> saveTrip(Trip trip) async {
    try {
      await _localDataSource.addTrip(trip);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateTrip(Trip trip) async {
    try {
      await _localDataSource.updateTrip(trip);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteTrip(String id) async {
    try {
      await _localDataSource.deleteTrip(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> setActiveTrip(String userId, String? tripId) async {
    try {
      if (tripId != null) {
        await _localDataSource.setActiveTrip(tripId);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ========== Remote Operations ==========

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getRemoteTrips({
    int? page,
    int? limit,
    String? search,
  }) async {
    try {
      final result = await _remoteDataSource.getRemoteTrips(page: page, limit: limit, search: search);
      if (result is Success<PaginatedList<Trip>, Exception>) {
        for (final trip in result.value.items) {
          await _localDataSource.addTrip(trip);
        }
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> uploadToCloud(Trip trip) async {
    return _remoteDataSource.uploadTrip(trip);
  }

  @override
  Future<Result<void, Exception>> removeFromCloud(String tripId) async {
    return _remoteDataSource.deleteTrip(tripId);
  }

  @override
  Future<Result<Trip, Exception>> syncTripDetails(String tripId) async {
    try {
      final result = await _remoteDataSource.getTripDetails(tripId);
      if (result is Success<Trip, Exception>) {
        await _localDataSource.updateTrip(result.value);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ========== Member Management (Remote) ==========

  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId) async {
    return _remoteDataSource.getTripMembers(tripId);
  }

  @override
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role) async {
    return _remoteDataSource.updateMemberRole(tripId, userId, role);
  }

  @override
  Future<Result<void, Exception>> removeMember(String tripId, String userId) async {
    return _remoteDataSource.removeMember(tripId, userId);
  }

  @override
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    return _remoteDataSource.addMemberByEmail(tripId, email, role: role);
  }

  @override
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    return _remoteDataSource.addMemberById(tripId, userId, role: role);
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email) async {
    return _remoteDataSource.searchUserByEmail(email);
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserById(String userId) async {
    return _remoteDataSource.searchUserById(userId);
  }
}
