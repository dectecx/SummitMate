import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';
import 'mock_itinerary_repository.dart';

/// 模擬行程清單資料庫
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

  // ========== Data Operations ==========

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
  Future<Result<void, Exception>> saveTrip(Trip trip) async {
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
  Future<Result<void, Exception>> setActiveTrip(String userId, String? tripId) async {
    return const Success(null);
  }

  // ========== Remote Operations ==========

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getRemoteTrips({int? page, int? limit, String? search}) async {
    return Success(PaginatedList(items: [_mockTrip], page: page ?? 1, total: 1, hasMore: false));
  }

  @override
  Future<Result<String, Exception>> uploadToCloud(Trip trip) async {
    return Success(trip.id);
  }

  @override
  Future<Result<void, Exception>> removeFromCloud(String tripId) async {
    return const Success(null);
  }

  @override
  Future<Result<Trip, Exception>> syncTripDetails(String tripId) async {
    return Success(_mockTrip);
  }

  // ========== Member Management (Remote Mock) ==========

  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId) async {
    return Success([
      {'id': 'mock-user-1', 'displayName': '測試帳號', 'email': 'test@example.com', 'role': 'owner'},
    ]);
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
    return Success(UserProfile(id: 'mock-user-2', email: email, displayName: '搜尋到的用戶', avatar: '🐻'));
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserById(String userId) async {
    return Success(UserProfile(id: userId, email: 'user@example.com', displayName: '搜尋到的用戶', avatar: '🐻'));
  }
}
