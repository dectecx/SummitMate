import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../env_config.dart';
import '../../infrastructure/infrastructure.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @preResolve
  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();

  @preResolve
  @singleton
  Future<HiveService> get hiveService async {
    final service = HiveService();
    await service.init();
    return service;
  }

  @Named('baseUrl')
  String get baseUrl => EnvConfig.apiBaseUrl;

  @lazySingleton
  Dio dio(AuthInterceptor authInterceptor) {
    final dio = Dio();
    dio.interceptors.add(authInterceptor);
    return dio;
  }

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  InternetConnectionChecker get internetConnectionChecker => InternetConnectionChecker.createInstance();
}
