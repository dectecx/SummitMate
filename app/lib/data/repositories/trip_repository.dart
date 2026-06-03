import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';

@LazySingleton(as: ITripRepository)
class TripRepository implements ITripRepository {
  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  final _tripUpdateController = StreamController<String>.broadcast();

  TripRepository(this._localDataSource, this._remoteDataSource);

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
      final marked = trip.copyWith(syncStatus: SyncStatus.pendingCreate, updatedAt: now);
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
