import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Infrastructure
import '../infrastructure/infrastructure.dart';

// Core Services
import '../core/services/permission_service.dart';

// Domain - Interfaces
import '../domain/interfaces/i_api_client.dart';
import '../domain/interfaces/i_connectivity_service.dart';
import '../domain/interfaces/i_weather_service.dart';
import '../domain/interfaces/i_poll_service.dart';
import '../domain/interfaces/i_geolocator_service.dart';
import '../domain/interfaces/i_gear_cloud_service.dart';
import '../domain/interfaces/i_auth_service.dart';
import '../domain/interfaces/i_token_validator.dart';
import '../domain/interfaces/i_sync_service.dart';
import '../domain/interfaces/i_data_service.dart';
import '../domain/interfaces/i_ad_service.dart';

// Data
import '../data/data.dart';
// Data Sources Interfaces & Implementations
import '../data/datasources/interfaces/i_group_event_local_data_source.dart';
import '../data/datasources/interfaces/i_group_event_remote_data_source.dart';
import '../data/datasources/local/group_event_local_data_source.dart';
import '../data/datasources/remote/group_event_remote_data_source.dart';
import '../data/datasources/interfaces/i_poll_local_data_source.dart';
import '../data/datasources/interfaces/i_poll_remote_data_source.dart';
import '../data/datasources/local/poll_local_data_source.dart';
import '../data/datasources/remote/poll_remote_data_source.dart';

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
import '../data/datasources/interfaces/i_gear_library_local_data_source.dart';
import '../data/datasources/local/gear_library_local_data_source.dart';
import '../data/datasources/interfaces/i_settings_local_data_source.dart';
import '../data/datasources/local/settings_local_data_source.dart';
import '../data/datasources/interfaces/i_auth_session_local_data_source.dart';
import '../data/datasources/local/auth_session_local_data_source.dart';

// Presentation
import '../presentation/cubits/group_event/comment/group_event_comment_cubit.dart';

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
  // ===========================================================================
  // 1. System & Common Infrastructure (基礎設施)
  // ===========================================================================
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // PackageInfo
  final packageInfo = await PackageInfo.fromPlatform();
  getIt.registerSingleton<PackageInfo>(packageInfo);

  // Hive (Local DB)
  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  // Logging
  await LogService.init();
  LogService.info('App 啟動', source: 'DI');

  // ===========================================================================
  // 2. Settings & Configuration (設定與配置)
  // ===========================================================================
  final settingsLocalDS = SettingsLocalDataSource(hiveService: hiveService);
  await settingsLocalDS.init();
  getIt.registerSingleton<ISettingsLocalDataSource>(settingsLocalDS);

  final settingsRepo = SettingsRepository(localDataSource: getIt<ISettingsLocalDataSource>());
  await settingsRepo.init();
  getIt.registerSingleton<ISettingsRepository>(settingsRepo);

  // Connectivity (Depends on Settings)
  getIt.registerLazySingleton<IConnectivityService>(() => ConnectivityService(settingsRepo: settingsRepo));

  // ===========================================================================
  // 3. Authentication (身份驗證)
  // ===========================================================================
  // Auth Session Data Source & Repository
  final authSessionLocalDS = AuthSessionLocalDataSource();
  getIt.registerSingleton<IAuthSessionLocalDataSource>(authSessionLocalDS);

  final authSessionRepo = AuthSessionRepository(localDataSource: getIt<IAuthSessionLocalDataSource>());
  getIt.registerSingleton<IAuthSessionRepository>(authSessionRepo);

  // Token Validator & Main Auth Service
  getIt.registerLazySingleton<ITokenValidator>(() => JwtTokenValidator());
  getIt.registerLazySingleton<IAuthService>(
    () => GasAuthService(sessionRepository: getIt<IAuthSessionRepository>(), tokenValidator: getIt<ITokenValidator>()),
  );

  // Permission Service (Context-aware wrapper over Auth/Settings often)
  getIt.registerLazySingleton<PermissionService>(() => PermissionService(getIt<IAuthService>()));

  // ===========================================================================
  // 4. Network Core (網路核心)
  // ===========================================================================
  // Auth Interceptor (Depends on AuthRepo)
  getIt.registerLazySingleton<AuthInterceptor>(() => AuthInterceptor(getIt<IAuthSessionRepository>()));

  // Dio Client
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.interceptors.add(getIt<AuthInterceptor>());
    return dio;
  });

  // API Clients
  getIt.registerLazySingleton<IApiClient>(
    () => GasApiClient(baseUrl: EnvConfig.gasBaseUrl, dio: getIt<Dio>()),
    instanceName: 'gas',
  );

  getIt.registerLazySingleton<NetworkAwareClient>(
    () => NetworkAwareClient(
      apiClient: getIt<IApiClient>(instanceName: 'gas'),
      connectivity: getIt<IConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<IApiClient>(() => getIt<NetworkAwareClient>());

  getIt.registerLazySingleton<UsageTrackingService>(() => UsageTrackingService(apiClient: getIt<IApiClient>()));

  // ===========================================================================
  // 5. Data Sources (資料來源)
  // ===========================================================================
  // --- Local Data Sources ---
  final tripLocalDS = TripLocalDataSource(hiveService: hiveService);
  await tripLocalDS.init();
  getIt.registerSingleton<ITripLocalDataSource>(tripLocalDS);

  final itineraryLocalDS = ItineraryLocalDataSource(hiveService: hiveService);
  await itineraryLocalDS.init();
  getIt.registerSingleton<IItineraryLocalDataSource>(itineraryLocalDS);

  final gearLocalDS = GearLocalDataSource(hiveService: hiveService);
  await gearLocalDS.init();
  getIt.registerSingleton<IGearLocalDataSource>(gearLocalDS);

  final messageLocalDS = MessageLocalDataSource(hiveService: hiveService);
  await messageLocalDS.init();
  getIt.registerSingleton<IMessageLocalDataSource>(messageLocalDS);

  final gearLibLocalDS = GearLibraryLocalDataSource(hiveService: hiveService);
  await gearLibLocalDS.init();
  getIt.registerSingleton<IGearLibraryLocalDataSource>(gearLibLocalDS);

  final pollLocalDS = PollLocalDataSource(hiveService: hiveService);
  await pollLocalDS.init();
  getIt.registerSingleton<IPollLocalDataSource>(pollLocalDS);

  final groupEventLocalDS = GroupEventLocalDataSource(hiveService: hiveService);
  await groupEventLocalDS.init();
  getIt.registerSingleton<IGroupEventLocalDataSource>(groupEventLocalDS);

  final gearKeyLocalDS = GearKeyLocalDataSource();
  getIt.registerSingleton<IGearKeyLocalDataSource>(gearKeyLocalDS);

  // --- Remote Data Sources ---
  getIt.registerLazySingleton<ITripRemoteDataSource>(() => TripRemoteDataSource());
  getIt.registerLazySingleton<IItineraryRemoteDataSource>(() => ItineraryRemoteDataSource());
  getIt.registerLazySingleton<IMessageRemoteDataSource>(() => MessageRemoteDataSource());
  getIt.registerLazySingleton<IGearCloudService>(() => GearCloudService());
  getIt.registerLazySingleton<IPollRemoteDataSource>(() => PollRemoteDataSource());
  getIt.registerLazySingleton<IGroupEventRemoteDataSource>(() => GroupEventRemoteDataSource());

  // ===========================================================================
  // 6. Repositories (倉儲層)
  // ===========================================================================
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

  final gearLibraryRepo = GearLibraryRepository(localDataSource: getIt<IGearLibraryLocalDataSource>());
  getIt.registerSingleton<IGearLibraryRepository>(gearLibraryRepo);

  final pollRepo = PollRepository(
    localDataSource: getIt<IPollLocalDataSource>(),
    remoteDataSource: getIt<IPollRemoteDataSource>(),
  );
  getIt.registerSingleton<IPollRepository>(pollRepo);

  final gearSetRepo = GearSetRepository();
  getIt.registerSingleton<IGearSetRepository>(gearSetRepo);

  final groupEventRepo = GroupEventRepository(
    localDataSource: getIt<IGroupEventLocalDataSource>(),
    remoteDataSource: getIt<IGroupEventRemoteDataSource>(),
    authService: getIt<IAuthService>(),
  );
  getIt.registerSingleton<IGroupEventRepository>(groupEventRepo);

  // ===========================================================================
  // 7. Domain & Application Services (應用服務)
  // ===========================================================================
  // Location
  getIt.registerLazySingleton<ILocationResolver>(() => TownshipLocationResolver());
  getIt.registerLazySingleton<IGeolocatorService>(() => GeolocatorService());

  // Feature Services
  final weatherService = WeatherService();
  await weatherService.init();
  getIt.registerSingleton<IWeatherService>(weatherService);

  getIt.registerSingleton<IPollService>(PollService());

  // Data & Sync
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

  // Subscriptions & Ads
  final adService = AdService();
  await adService.initialize();
  getIt.registerSingleton<IAdService>(adService);

  // ===========================================================================
  // 8. Presentation Factories (Bloc/Cubit 工廠)
  // ===========================================================================
  // GroupEventCommentCubit (Dynamic Factory)
  getIt.registerFactoryParam<GroupEventCommentCubit, String, void>(
    (eventId, _) => GroupEventCommentCubit(
      repository: getIt<IGroupEventRepository>(),
      authService: getIt<IAuthService>(),
      eventId: eventId,
    ),
  );
}

/// 重置依賴注入 (用於測試)
Future<void> resetDependencies() async {
  await getIt.reset();
}
