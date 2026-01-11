import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Infrastructure - Tools
import '../infrastructure/tools/hive_service.dart';
import '../infrastructure/tools/log_service.dart';

// Infrastructure - Services
import '../infrastructure/services/google_sheets_service.dart';
import '../infrastructure/services/sync_service.dart';
import '../infrastructure/services/connectivity_service.dart';
import '../infrastructure/services/weather_service.dart';
import '../infrastructure/services/poll_service.dart';
import '../infrastructure/services/geolocator_service.dart';
import '../infrastructure/services/gear_cloud_service.dart';
import '../infrastructure/services/gas_auth_service.dart';
import '../infrastructure/services/jwt_token_validator.dart';

// Infrastructure - Clients
import '../infrastructure/clients/network_aware_client.dart';
import '../infrastructure/clients/gas_api_client.dart';
import '../infrastructure/tools/usage_tracking_service.dart';

// Infrastructure - Interceptors
import '../infrastructure/interceptors/auth_interceptor.dart';

// Domain - Interfaces
import '../domain/interfaces/i_connectivity_service.dart';
import '../domain/interfaces/i_weather_service.dart';
import '../domain/interfaces/i_poll_service.dart';
import '../domain/interfaces/i_geolocator_service.dart';
import '../domain/interfaces/i_gear_cloud_service.dart';
import '../domain/interfaces/i_auth_service.dart';
import '../domain/interfaces/i_token_validator.dart';
import '../domain/interfaces/i_sync_service.dart';
import '../domain/interfaces/i_data_service.dart';

// Data - Repositories
import '../data/repositories/settings_repository.dart';
import '../data/repositories/itinerary_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/gear_repository.dart';
import '../data/repositories/gear_library_repository.dart';
import '../data/repositories/poll_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../data/repositories/gear_set_repository.dart';
import '../data/repositories/auth_session_repository.dart';

// Data - Repository Interfaces
import '../data/repositories/interfaces/i_gear_repository.dart';
import '../data/repositories/interfaces/i_gear_library_repository.dart';
import '../data/repositories/interfaces/i_auth_session_repository.dart';
import '../data/repositories/interfaces/i_settings_repository.dart';
import '../data/repositories/interfaces/i_itinerary_repository.dart';
import '../data/repositories/interfaces/i_message_repository.dart';
import '../data/repositories/interfaces/i_poll_repository.dart';
import '../data/repositories/interfaces/i_trip_repository.dart';
import '../data/repositories/interfaces/i_gear_set_repository.dart';

// Data - DataSources
import '../data/datasources/local/trip_local_data_source.dart';
import '../data/datasources/remote/trip_remote_data_source.dart';
import '../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../data/datasources/interfaces/i_trip_remote_data_source.dart';
import '../data/datasources/local/gear_local_data_source.dart';
import '../data/datasources/interfaces/i_gear_local_data_source.dart';
import '../data/datasources/local/message_local_data_source.dart';
import '../data/datasources/interfaces/i_message_local_data_source.dart';
import '../data/datasources/remote/message_remote_data_source.dart';
import '../data/datasources/interfaces/i_message_remote_data_source.dart';
import '../data/datasources/local/itinerary_local_data_source.dart';
import '../data/datasources/interfaces/i_itinerary_local_data_source.dart';
import '../data/datasources/remote/itinerary_remote_data_source.dart';
import '../data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import '../data/datasources/local/gear_key_local_data_source.dart';
import '../data/datasources/interfaces/i_gear_key_local_data_source.dart';

// Presentation

// Core
import '../core/location/i_location_resolver.dart';
import '../core/location/township_location_resolver.dart';
import '../core/env_config.dart';
import 'package:dio/dio.dart';

/// 全域依賴注入容器
final GetIt getIt = GetIt.instance;

/// 初始化依賴注入
/// 在 App 啟動時呼叫，註冊所有服務與 Repository
Future<void> setupDependencies() async {
  // 1. 基本單例與服務 (SharedPreferences, PackageInfo, Hive, Log)
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  final packageInfo = await PackageInfo.fromPlatform();
  getIt.registerSingleton<PackageInfo>(packageInfo);

  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  await LogService.init();
  LogService.info('App 啟動', source: 'DI');

  // 2. 設定與身份驗證基礎 (Settings, Auth Core, Network Core)
  // Settings Repository (Early initialization needed for Connectivity and Sync)
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();
  getIt.registerSingleton<ISettingsRepository>(settingsRepo);

  // Connectivity
  getIt.registerLazySingleton<IConnectivityService>(() => ConnectivityService(settingsRepo: settingsRepo));

  // Auth Core
  final authSessionRepo = AuthSessionRepository();
  getIt.registerSingleton<IAuthSessionRepository>(authSessionRepo);
  getIt.registerLazySingleton<ITokenValidator>(() => JwtTokenValidator());
  getIt.registerLazySingleton<IAuthService>(
    () => GasAuthService(sessionRepository: getIt<IAuthSessionRepository>(), tokenValidator: getIt<ITokenValidator>()),
  );

  // Network Core (Dio & API Clients)
  getIt.registerLazySingleton<AuthInterceptor>(() => AuthInterceptor(getIt<IAuthSessionRepository>()));
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.interceptors.add(getIt<AuthInterceptor>());
    return dio;
  });
  getIt.registerLazySingleton<GasApiClient>(() => GasApiClient(baseUrl: EnvConfig.gasBaseUrl, dio: getIt<Dio>()));
  getIt.registerLazySingleton<NetworkAwareClient>(
    () => NetworkAwareClient(apiClient: getIt<GasApiClient>(), connectivity: getIt<IConnectivityService>()),
  );
  getIt.registerLazySingleton<UsageTrackingService>(() => UsageTrackingService(apiClient: getIt<GasApiClient>()));

  // 3. Data Sources (Depends on Network Core)
  final tripLocalDS = TripLocalDataSource();
  await tripLocalDS.init();
  getIt.registerSingleton<ITripLocalDataSource>(tripLocalDS);

  final itineraryLocalDS = ItineraryLocalDataSource();
  await itineraryLocalDS.init();
  getIt.registerSingleton<IItineraryLocalDataSource>(itineraryLocalDS);

  final gearLocalDS = GearLocalDataSource();
  await gearLocalDS.init();
  getIt.registerSingleton<IGearLocalDataSource>(gearLocalDS);

  final messageLocalDS = MessageLocalDataSource();
  await messageLocalDS.init();
  getIt.registerSingleton<IMessageLocalDataSource>(messageLocalDS);

  final gearKeyLocalDS = GearKeyLocalDataSource();
  getIt.registerSingleton<IGearKeyLocalDataSource>(gearKeyLocalDS);

  getIt.registerLazySingleton<ITripRemoteDataSource>(() => TripRemoteDataSource());
  getIt.registerLazySingleton<IItineraryRemoteDataSource>(() => ItineraryRemoteDataSource());
  getIt.registerLazySingleton<IMessageRemoteDataSource>(() => MessageRemoteDataSource());
  getIt.registerLazySingleton<IGearCloudService>(() => GearCloudService());

  // 4. Repositories (Depends on Data Sources & Network Core)
  final tripRepo = TripRepository(
    localDataSource: getIt<ITripLocalDataSource>(),
    remoteDataSource: getIt<ITripRemoteDataSource>(),
  );
  await tripRepo.init();
  getIt.registerSingleton<ITripRepository>(tripRepo);

  final itineraryRepo = ItineraryRepository(
    localDataSource: getIt<IItineraryLocalDataSource>(),
    remoteDataSource: getIt<IItineraryRemoteDataSource>(),
    connectivity: getIt<IConnectivityService>(),
  );
  await itineraryRepo.init();
  getIt.registerSingleton<IItineraryRepository>(itineraryRepo);

  final messageRepo = MessageRepository();
  await messageRepo.init();
  getIt.registerSingleton<IMessageRepository>(messageRepo);

  final gearRepo = GearRepository();
  await gearRepo.init();
  getIt.registerSingleton<IGearRepository>(gearRepo);

  final gearLibraryRepo = GearLibraryRepository();
  await gearLibraryRepo.init();
  getIt.registerSingleton<IGearLibraryRepository>(gearLibraryRepo);

  final pollRepo = PollRepository();
  await pollRepo.init();
  getIt.registerSingleton<IPollRepository>(pollRepo);

  final gearSetRepo = GearSetRepository();
  getIt.registerSingleton<IGearSetRepository>(gearSetRepo);

  // 5. Additional Services & Utils
  getIt.registerLazySingleton<ILocationResolver>(() => TownshipLocationResolver());
  getIt.registerLazySingleton<IGeolocatorService>(() => GeolocatorService());

  final weatherService = WeatherService();
  await weatherService.init();
  getIt.registerSingleton<IWeatherService>(weatherService);

  getIt.registerSingleton<IPollService>(PollService());
  getIt.registerLazySingleton<IDataService>(() => GoogleSheetsService());

  getIt.registerLazySingleton<ISyncService>(
    () => SyncService(
      sheetsService: getIt<IDataService>(),
      tripRepo: getIt<ITripRepository>(),
      itineraryRepo: getIt<IItineraryRepository>(),
      messageRepo: getIt<IMessageRepository>(),
      connectivity: getIt<IConnectivityService>(),
      authService: getIt<IAuthService>(),
    ),
  );
}

/// 重置依賴注入 (用於測試)
Future<void> resetDependencies() async {
  await getIt.reset();
}
