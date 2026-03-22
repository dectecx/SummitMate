import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../infrastructure/infrastructure.dart';
import '../../infrastructure/tools/log_service.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: true, asExtension: true)
Future<void> configureDependencies() async {
  LogService.info('🚀 [DI] Starting dependencies setup...');

  // 1. 並行執行非依賴性異步任務 (Optimization)
  LogService.info('🚀 [DI] Stage 1: Parallel Initialization (Prefs, PackageInfo, Hive)');
  final results = await Future.wait([SharedPreferences.getInstance(), PackageInfo.fromPlatform(), _initHive()]);

  // 2. 手動註冊這些實例，以便 injectable 的 init 可以直接使用它們
  getIt.registerSingleton<SharedPreferences>(results[0] as SharedPreferences);
  getIt.registerSingleton<PackageInfo>(results[1] as PackageInfo);
  getIt.registerSingleton<HiveService>(results[2] as HiveService);

  // 3. 執行產生的 init (處理剩餘的依賴與注入)
  LogService.info('🚀 [DI] Stage 2: Injectable Initialization');
  await getIt.init();

  LogService.info('✅ [DI] Dependencies setup completed.');
}

Future<HiveService> _initHive() async {
  final service = HiveService();
  await service.init();
  return service;
}
