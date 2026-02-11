import '../../../core/error/result.dart';
import '../../models/user_profile.dart';
import '../../models/enums/sync_status.dart';
import '../../models/trip.dart';
import '../interfaces/i_trip_repository.dart';
import 'mock_itinerary_repository.dart';

/// 模擬行程清單資料庫
/// 用於教學模式，返回單一假行程，所有寫入操作皆為空實作。
class MockTripRepository implements ITripRepository {
  /// 模擬行程
  final Trip _mockTrip = Trip(
    id: MockItineraryRepository.mockTripId,
    userId: 'mock-user-1',
    name: '嘉明湖三天兩夜',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 2)),
    description: '向陽山 + 三叉山 + 嘉明湖',
    isActive: true,
    syncStatus: SyncStatus.synced,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    createdBy: 'mock-user-1',
    updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedBy: 'mock-user-1',
  );

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  Future<Result<List<Trip>, Exception>> getAllTrips(String userId) async {
    return Success([_mockTrip]);
  }

  @override
  Future<Result<Trip?, Exception>> getActiveTrip(String userId) async {
    return Success(_mockTrip);
  }

  @override
  Future<Result<Trip?, Exception>> getTripById(String id) async {
    return Success(id == _mockTrip.id ? _mockTrip : null);
  }

  @override
  Future<Result<void, Exception>> addTrip(Trip trip) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> updateTrip(Trip trip) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> deleteTrip(String id) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> setActiveTrip(String tripId) async {
    return const Success(null);
  }

  @override
  Future<Result<DateTime?, Exception>> getLastSyncTime() async {
    return Success(DateTime.now());
  }

  @override
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time) async {
    return const Success(null);
  }

  @override
  Future<Result<List<Trip>, Exception>> getRemoteTrips() async {
    return Success([_mockTrip]);
  }

  @override
  Future<Result<String, Exception>> uploadTripToRemote(Trip trip) async {
    return Success(trip.id);
  }

  @override
  Future<Result<void, Exception>> deleteRemoteTrip(String id) async {
    return const Success(null);
  }

  @override
  Future<Result<String, Exception>> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async {
    return Success(trip.id);
  }

  @override
  Future<Result<void, Exception>> clearAll() async {
    return const Success(null);
  }

  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId) async {
    return const Success([]);
  }

  @override
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> removeMember(String tripId, String userId) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    return const Success(null);
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email) async {
    return Success(UserProfile(id: 'mock-user-2', email: email, displayName: 'Mock User'));
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserById(String userId) async {
    return Success(UserProfile(id: userId, email: 'mock@example.com', displayName: 'Mock User'));
  }
}
