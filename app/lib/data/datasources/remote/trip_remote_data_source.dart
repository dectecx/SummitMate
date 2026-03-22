import 'package:injectable/injectable.dart';
import '../../../core/di/injection.dart';
import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_remote_data_source.dart';

/// 行程 (Trip) 的遠端資料來源實作
@LazySingleton(as: ITripRemoteDataSource)
class TripRemoteDataSource implements ITripRemoteDataSource {
  static const String _source = 'TripRemoteDataSource';

  final NetworkAwareClient _apiClient;

  TripRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得雲端行程列表
  @override
  Future<List<Trip>> getTrips() async {
    try {
      LogService.info('取得雲端行程列表...', source: _source);
      final response = await _apiClient.get('/trips');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Trip.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      LogService.error('Remote GetTrips failed: $e', source: _source);
      rethrow;
    }
  }

  /// 上傳新行程
  ///
  /// [trip] 行程資料
  /// 回傳新建立的行程 ID
  @override
  Future<String> uploadTrip(Trip trip) async {
    try {
      final response = await _apiClient.post(
        '/trips',
        data: {
          'name': trip.name,
          'start_date': trip.startDate.toIso8601String(),
          'end_date': trip.endDate?.toIso8601String() ?? '',
          'description': trip.description ?? '',
          'cover_image': trip.coverImage ?? '',
          'is_active': trip.isActive,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['id'] as String? ?? trip.id;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote UploadTrip failed: $e', source: _source);
      rethrow;
    }
  }

  /// 更新雲端行程資料
  ///
  /// [trip] 更新後的行程資料
  @override
  Future<void> updateTrip(Trip trip) async {
    try {
      final response = await _apiClient.put(
        '/trips/${trip.id}',
        data: {
          'name': trip.name,
          'start_date': trip.startDate.toIso8601String(),
          'end_date': trip.endDate?.toIso8601String() ?? '',
          'description': trip.description ?? '',
          'cover_image': trip.coverImage ?? '',
          'is_active': trip.isActive,
        },
      );

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote UpdateTrip failed: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除雲端行程
  ///
  /// [tripId] 目標行程 ID
  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      final response = await _apiClient.delete('/trips/$tripId');
      if (response.statusCode != 200 && response.statusCode != 204) throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote DeleteTrip failed: $e', source: _source);
      rethrow;
    }
  }

  /// 取得行程成員列表
  ///
  /// [tripId] 行程 ID
  @override
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/members');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote GetTripMembers failed: $e', source: _source);
      rethrow;
    }
  }

  /// 更新成員角色
  ///
  /// [tripId] 行程 ID
  /// [userId] 目標成員 ID
  /// [role] 新角色身分代碼 (參考 RoleConstants)
  @override
  Future<void> updateMemberRole(String tripId, String userId, String role) async {
    try {
      final response = await _apiClient.put('/trips/$tripId/members/$userId', data: {'role': role});
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote UpdateMemberRole failed: $e', source: _source);
      rethrow;
    }
  }

  /// 移除成員
  ///
  /// [tripId] 行程 ID
  /// [userId] 目標成員 ID
  @override
  Future<void> removeMember(String tripId, String userId) async {
    try {
      final response = await _apiClient.delete('/trips/$tripId/members/$userId');
      if (response.statusCode != 200 && response.statusCode != 204) throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote RemoveMember failed: $e', source: _source);
      rethrow;
    }
  }

  /// 新增成員 (透過 Email)
  ///
  /// [tripId] 行程 ID
  /// [email] 成員 Email
  /// [role] 初始角色
  @override
  Future<void> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    try {
      final response = await _apiClient.post('/trips/$tripId/members', data: {'email': email, 'role': role});
      if (response.statusCode != 200 && response.statusCode != 201) throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote AddMemberByEmail failed: $e', source: _source);
      rethrow;
    }
  }

  /// 新增成員 (透過 User ID)
  ///
  /// [tripId] 行程 ID
  /// [userId] 成員 User ID
  /// [role] 初始角色
  @override
  Future<void> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    try {
      final response = await _apiClient.post('/trips/$tripId/members', data: {'user_id': userId, 'role': role});
      if (response.statusCode != 200 && response.statusCode != 201) throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote AddMemberById failed: $e', source: _source);
      rethrow;
    }
  }

  /// 透過 Email 搜尋使用者
  ///
  /// [email] 使用者 Email
  @override
  Future<UserProfile> searchUserByEmail(String email) async {
    try {
      LogService.info('Searching user by email: $email', source: _source);
      final response = await _apiClient.get('/users/search', queryParameters: {'email': email});

      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('Remote SearchUserByEmail failed: $e', source: _source);
      rethrow;
    }
  }

  /// 透過 ID 搜尋使用者
  ///
  /// [userId] 使用者 ID
  @override
  Future<UserProfile> searchUserById(String userId) async {
    try {
      LogService.info('Searching user by ID: $userId', source: _source);
      final response = await _apiClient.get('/users/$userId');

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
