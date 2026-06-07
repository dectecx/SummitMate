import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/result.dart';
import '../../core/exceptions/offline_exception.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';

@LazySingleton(as: ITripRepository)
class TripRepository implements ITripRepository {
  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;
  final IConnectivityService _connectivityService;

  final _tripUpdateController = StreamController<String>.broadcast();

  TripRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._connectivityService,
  );

  @override
  Stream<String> get tripUpdateStream => _tripUpdateController.stream;

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  // ========== Data Operations ==========

  @override
  Future<Result<List<Trip>, Exception>> getAllTrips(String userId) async {
    try {
      final trips = await _localDataSource.getAllTrips();
      final userTrips = trips.where((t) => t.userId == userId).toList();
      userTrips.sort((a, b) => b.startDate.compareTo(a.startDate));
      return Success(userTrips);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<Trip?, Exception>> getActiveTrip(String userId) async {
    try {
      final trip = await _localDataSource.getActiveTrip(userId);
      return Success(trip);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<Trip?, Exception>> getTripById(String id) async {
    try {
      final trip = await _localDataSource.getTripById(id);
      return Success(trip);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> saveTrip(Trip trip) async {
    try {
      final now = DateTime.now();
      final newStatus = trip.syncStatus == SyncStatus.synced ? SyncStatus.synced : SyncStatus.pendingCreate;
      final marked = trip.copyWith(syncStatus: newStatus, updatedAt: now);
      await _localDataSource.addTrip(marked);
      _tripUpdateController.add(trip.id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateTrip(Trip trip) async {
    try {
      final existing = await _localDataSource.getTripById(trip.id);
      final newStatus = existing?.syncStatus == SyncStatus.pendingCreate
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate;
      final marked = trip.copyWith(syncStatus: newStatus, updatedAt: DateTime.now());
      await _localDataSource.updateTrip(marked);
      _tripUpdateController.add(trip.id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteTrip(String id) async {
    try {
      final existing = await _localDataSource.getTripById(id);
      if (existing == null) {
        return const Success(null);
      }
      if (existing.syncStatus == SyncStatus.pendingCreate) {
        await _localDataSource.deleteTrip(id);
      } else {
        await _localDataSource.updateTrip(
          existing.copyWith(syncStatus: SyncStatus.pendingDelete, updatedAt: DateTime.now()),
        );
      }
      _tripUpdateController.add(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> setActiveTrip(String userId, String? tripId) async {
    try {
      if (tripId != null) {
        await _localDataSource.setActiveTrip(userId, tripId);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ========== Remote Operations ==========

  // ========== Member Management (Remote) ==========

  @override
  Future<Result<List<TripMember>, Exception>> getTripMembers(String tripId) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'getTripMembers'));
    }
    return _remoteDataSource.getTripMembers(tripId);
  }

  @override
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'updateMemberRole'));
    }
    return _remoteDataSource.updateMemberRole(tripId, userId, role);
  }

  @override
  Future<Result<void, Exception>> transferOwnership(
    String tripId,
    String targetUserId,
    String currentOwnerRole,
  ) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'transferOwnership'));
    }

    try {
      final remoteResult = await _remoteDataSource.transferOwnership(tripId, targetUserId, currentOwnerRole);
      if (remoteResult is Failure) {
        return Failure((remoteResult as Failure).exception);
      }

      final updatedTrip = (remoteResult as Success<Trip, Exception>).value;

      await _localDataSource.updateTrip(updatedTrip.copyWith(syncStatus: SyncStatus.synced));
      _tripUpdateController.add(tripId);

      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }


  @override
  Future<Result<void, Exception>> removeMember(String tripId, String userId) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'removeMember'));
    }
    return _remoteDataSource.removeMember(tripId, userId);
  }

  @override
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'addMemberByEmail'));
    }
    return _remoteDataSource.addMemberByEmail(tripId, email, role: role);
  }

  @override
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'addMemberById'));
    }
    return _remoteDataSource.addMemberById(tripId, userId, role: role);
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'searchUserByEmail'));
    }
    return _remoteDataSource.searchUserByEmail(email);
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserById(String userId) async {
    if (_connectivityService.isOffline) {
      return const Failure(OfflineException('此功能在離線時不可用', operationName: 'searchUserById'));
    }
    return _remoteDataSource.searchUserById(userId);
  }

  // ========== Meal Plan Day Operations ==========

  @override
  Future<Result<List<MealPlanDay>, Exception>> getMealPlanDays(String tripId) async {
    try {
      final days = await _localDataSource.getMealPlanDays(tripId);
      return Success(days);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<MealPlanDay, Exception>> addMealPlanDay(
    String tripId,
    String name, {
    String? linkedItineraryDay,
  }) async {
    try {
      final day = MealPlanDay(id: const Uuid().v7(), name: name, linkedItineraryDay: linkedItineraryDay);
      await _localDataSource.saveMealPlanDay(day, tripId);
      return Success(day);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<MealPlanDay, Exception>> updateMealPlanDay(
    String tripId,
    String dayId,
    String name, {
    String? linkedItineraryDay,
  }) async {
    try {
      final day = MealPlanDay(id: dayId, name: name, linkedItineraryDay: linkedItineraryDay);
      await _localDataSource.saveMealPlanDay(day, tripId);
      return Success(day);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> deleteMealPlanDay(String tripId, String dayId) async {
    try {
      await _localDataSource.deleteMealPlanDay(dayId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateLocalTripId(String oldId, String newId) async {
    try {
      await _localDataSource.migrateTripId(oldId, newId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> markTripAsPendingUpdate(String tripId) async {
    try {
      await _localDataSource.markTripAsPendingUpdate(tripId);
      _tripUpdateController.add(tripId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
