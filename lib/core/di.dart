import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/hive_service.dart';
import '../services/google_sheets_service.dart';
import '../services/sync_service.dart';
import '../services/log_service.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/itinerary_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/gear_repository.dart';

/// 全域依賴注入容器
final GetIt getIt = GetIt.instance;

/// 初始化依賴注入
/// 在 App 啟動時呼叫，註冊所有服務與 Repository
Future<void> setupDependencies() async {
  // Singleton: SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Singleton: HiveService
  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  // LogService 初始化
  await LogService.init();
  LogService.info('App 啟動', source: 'DI');

  // Repositories (需要先初始化)
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();
  getIt.registerSingleton<SettingsRepository>(settingsRepo);

  final itineraryRepo = ItineraryRepository();
  await itineraryRepo.init();
  getIt.registerSingleton<ItineraryRepository>(itineraryRepo);

  final messageRepo = MessageRepository();
  await messageRepo.init();
  getIt.registerSingleton<MessageRepository>(messageRepo);

  final gearRepo = GearRepository();
  await gearRepo.init();
  getIt.registerSingleton<GearRepository>(gearRepo);

  // Services
  getIt.registerLazySingleton<GoogleSheetsService>(
    () => GoogleSheetsService(),
  );
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      sheetsService: getIt<GoogleSheetsService>(),
      itineraryRepo: getIt<ItineraryRepository>(),
      messageRepo: getIt<MessageRepository>(),
    ),
  );
}

/// 重置依賴注入 (用於測試)
Future<void> resetDependencies() async {
  await getIt.reset();
}
