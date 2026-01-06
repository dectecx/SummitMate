import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/hive_service.dart';
import '../services/google_sheets_service.dart';
import '../services/sync_service.dart';
import '../services/log_service.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/itinerary_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/gear_repository.dart';
import '../data/repositories/gear_library_repository.dart';
import '../data/repositories/poll_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../data/repositories/interfaces/i_gear_repository.dart';
import '../data/repositories/interfaces/i_gear_library_repository.dart';
import '../data/repositories/interfaces/i_settings_repository.dart';
import '../data/repositories/interfaces/i_itinerary_repository.dart';
import '../data/repositories/interfaces/i_message_repository.dart';
import '../data/repositories/interfaces/i_poll_repository.dart';
import '../data/repositories/interfaces/i_trip_repository.dart';
import '../services/weather_service.dart';
import '../services/interfaces/i_weather_service.dart';
import '../services/poll_service.dart';
import '../services/geolocator_service.dart';
import '../services/interfaces/i_geolocator_service.dart';
import '../presentation/providers/gear_provider.dart';
import '../core/location/i_location_resolver.dart';
import '../core/location/township_location_resolver.dart';
import '../services/gas_api_client.dart';
import '../services/auth_service.dart';
import '../core/env_config.dart';

/// 全域依賴注入容器
final GetIt getIt = GetIt.instance;

/// 初始化依賴注入
/// 在 App 啟動時呼叫，註冊所有服務與 Repository
Future<void> setupDependencies() async {
  // Singleton: SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Singleton: PackageInfo
  final packageInfo = await PackageInfo.fromPlatform();
  getIt.registerSingleton<PackageInfo>(packageInfo);

  // Singleton: HiveService
  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  // LogService 初始化
  await LogService.init();
  LogService.info('App 啟動', source: 'DI');

  // ========================================
  // Repositories
  // ========================================

  // 1. Trip - 最上層容器
  final tripRepo = TripRepository();
  await tripRepo.init();
  getIt.registerSingleton<ITripRepository>(tripRepo);

  // 2. Itinerary - 行程節點
  final itineraryRepo = ItineraryRepository();
  await itineraryRepo.init();
  getIt.registerSingleton<IItineraryRepository>(itineraryRepo);

  // 3. Messages - 留言
  final messageRepo = MessageRepository();
  await messageRepo.init();
  getIt.registerSingleton<IMessageRepository>(messageRepo);

  // 4. Gear - 行程裝備
  final gearRepo = GearRepository();
  await gearRepo.init();
  getIt.registerSingleton<IGearRepository>(gearRepo);

  // 5. GearLibrary - 個人裝備庫
  final gearLibraryRepo = GearLibraryRepository();
  await gearLibraryRepo.init();
  getIt.registerSingleton<IGearLibraryRepository>(gearLibraryRepo);

  // 5. Polls - 投票
  final pollRepo = PollRepository();
  await pollRepo.init();
  getIt.registerSingleton<IPollRepository>(pollRepo);

  // 6. Settings - 設定
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();
  getIt.registerSingleton<ISettingsRepository>(settingsRepo);

  // 7. Location Resolver
  getIt.registerLazySingleton<ILocationResolver>(() => TownshipLocationResolver());

  // 7.5 Geolocator Service
  getIt.registerLazySingleton<IGeolocatorService>(() => GeolocatorService());

  // 8. Weather - 氣象服務 (依賴 ISettingsRepository & ILocationResolver)
  final weatherService = WeatherService();
  await weatherService.init();
  getIt.registerSingleton<IWeatherService>(weatherService);

  // ========================================
  // Services
  // ========================================

  // PollService
  getIt.registerSingleton<PollService>(PollService());

  // Services
  getIt.registerLazySingleton<GoogleSheetsService>(() => GoogleSheetsService());
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      sheetsService: getIt<GoogleSheetsService>(),
      tripRepo: getIt<ITripRepository>(),
      itineraryRepo: getIt<IItineraryRepository>(),
      messageRepo: getIt<IMessageRepository>(),
      settingsRepo: getIt<ISettingsRepository>(),
    ),
  );

  // Providers (Singletons for access outside logic)
  getIt.registerLazySingleton<GearProvider>(() => GearProvider());

  // ========================================
  // Auth Services
  // ========================================

  // AuthService - Authentication (register first, used by GasApiClient)
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // GasApiClient - Core API Client with auth token injection
  getIt.registerLazySingleton<GasApiClient>(
    () => GasApiClient(
      baseUrl: EnvConfig.gasBaseUrl,
      authTokenProvider: () => getIt<AuthService>().getAuthToken(),
    ),
  );
}

/// 重置依賴注入 (用於測試)
Future<void> resetDependencies() async {
  await getIt.reset();
}
