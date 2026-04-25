import 'package:injectable/injectable.dart';
import '../../models/user_profile.dart';
import '../../api/services/user_api_service.dart';
import '../../api/mappers/user_api_mapper.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_user_remote_data_source.dart';

/// 使用者 (User) 的遠端資料來源實作
@LazySingleton(as: IUserRemoteDataSource)
class UserRemoteDataSource implements IUserRemoteDataSource {
  static const String _source = 'UserRemoteDataSource';

  final UserApiService _userApi;

  UserRemoteDataSource(this._userApi);

  @override
  Future<UserProfile> searchUserByEmail(String email) async {
    try {
      LogService.info('Searching user by email: $email', source: _source);
      final response = await _userApi.searchUserByEmail(email);
      return UserApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('SearchUserByEmail failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> getUserById(String userId) async {
    try {
      LogService.info('Fetching user by ID: $userId', source: _source);
      final response = await _userApi.getUserById(userId);
      return UserApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('GetUserById failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    try {
      LogService.info('Fetching current user profile', source: _source);
      final response = await _userApi.getCurrentUser();
      return UserApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('GetCurrentUser failed: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      LogService.info('Updating user profile', source: _source);
      final request = UserApiMapper.toUpdateRequest(profile);
      final response = await _userApi.updateProfile(request);
      return UserApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('UpdateProfile failed: $e', source: _source);
      rethrow;
    }
  }
}
