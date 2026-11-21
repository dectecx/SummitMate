import 'package:dio/dio.dart';

import '../../../core/auth/auth_api.dart';
import '../domain/member_logic.dart';

/// Looks people up by exact e-mail address (only verified, active accounts are found).
abstract interface class UserSearchApi {
  Future<List<FoundUser>> findByEmail(String email);
}

class DioUserSearchApi implements UserSearchApi {
  DioUserSearchApi(this._dio);
  final Dio _dio;

  @override
  Future<List<FoundUser>> findByEmail(String email) async {
    try {
      final res = await _dio.get<List<dynamic>>('/users/search', queryParameters: {'email': email});
      return [
        for (final u in res.data ?? const [])
          FoundUser(id: (u as Map)['id'] as String, displayName: u['display_name'] as String, avatar: u['avatar'] as String),
      ];
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw AuthNetworkException(e.type.name);
      final data = res.data;
      throw AuthException(status: res.statusCode ?? 0, code: data is Map && data['code'] is String ? data['code'] as String : 'http_${res.statusCode}');
    }
  }
}
