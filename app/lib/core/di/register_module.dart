import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../env_config.dart';
import '../../infrastructure/infrastructure.dart';
import '../../infrastructure/interceptors/connectivity_interceptor.dart';
import '../../infrastructure/database/app_database.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @preResolve
  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();

  @Named('baseUrl')
  String get baseUrl => EnvConfig.apiBaseUrl;

  @lazySingleton
  Dio dio(
    @Named('baseUrl') String baseUrl,
    AuthInterceptor authInterceptor,
    ConnectivityInterceptor connectivityInterceptor,
  ) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ));
    dio.interceptors.addAll([connectivityInterceptor, authInterceptor]);
    return dio;
  }

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  InternetConnectionChecker get internetConnectionChecker => InternetConnectionChecker.createInstance();

  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();
}
