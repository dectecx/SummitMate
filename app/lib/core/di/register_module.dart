import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import '../../infrastructure/infrastructure.dart';

@module
abstract class RegisterModule {
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();

  @singleton
  Future<HiveService> get hiveService async {
    final service = HiveService();
    await service.init();
    return service;
  }

  @lazySingleton
  Dio dio(AuthInterceptor authInterceptor) {
    final dio = Dio();
    dio.interceptors.add(authInterceptor);
    return dio;
  }
}
