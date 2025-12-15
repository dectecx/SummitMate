import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/isar_service.dart';
import '../services/google_sheets_service.dart';
import '../services/sync_service.dart';
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

  // Singleton: IsarService
  final isarService = IsarService();
  await isarService.init();
  getIt.registerSingleton<IsarService>(isarService);
  getIt.registerSingleton<Isar>(isarService.isar);

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt<Isar>()),
  );
  getIt.registerLazySingleton<ItineraryRepository>(
    () => ItineraryRepository(getIt<Isar>()),
  );
  getIt.registerLazySingleton<MessageRepository>(
    () => MessageRepository(getIt<Isar>()),
  );
  getIt.registerLazySingleton<GearRepository>(
    () => GearRepository(getIt<Isar>()),
  );

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
