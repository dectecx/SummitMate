import 'package:summitmate/domain/domain.dart';

/// 使用者遠端資料來源介面
abstract class IUserRemoteDataSource {
  /// 透過 Email 搜尋使用者
  Future<UserProfile> searchUserByEmail(String email);

  /// 透過 ID 獲取使用者資料
  Future<UserProfile> getUserById(String userId);

  /// 獲取當前登入使用者資料
  Future<UserProfile> getCurrentUser();

  /// 更新使用者資料
  Future<UserProfile> updateProfile(UserProfile profile);
}
