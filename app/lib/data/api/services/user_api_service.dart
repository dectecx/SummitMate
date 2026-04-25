import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_api_models.dart';

part 'user_api_service.g.dart';

/// User API Service
///
/// Retrofit 介面，對應後端 `/users` 相關的 API endpoint。
@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio, {String baseUrl}) = _UserApiService;

  /// 透過 Email 搜尋使用者
  @GET('/users/search')
  Future<UserResponse> searchUserByEmail(@Query('email') String email);

  /// 透過 ID 獲取使用者資料
  @GET('/users/{userId}')
  Future<UserResponse> getUserById(@Path('userId') String userId);

  /// 獲取當前登入使用者資料
  @GET('/users/me')
  Future<UserResponse> getCurrentUser();

  /// 更新使用者資料
  @PATCH('/users/me')
  Future<UserResponse> updateProfile(@Body() UserUpdateRequest request);
}
