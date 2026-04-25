import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../infrastructure/infrastructure.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: true, asExtension: true)
Future<void> configureDependencies() async {
  LogService.info('🚀 [DI] Starting dependencies setup...');

  // 1. 並行執行非依賴性異步任務 (Optimization)
  // 此處僅為「預熱」緩存，實際註冊將由 Stage 2 的 injectable 依據 RegisterModule 定義執行。
  LogService.info('🚀 [DI] Stage 1: Parallel Initialization (Prefs, PackageInfo, Hive)');
  await Future.wait([SharedPreferences.getInstance(), PackageInfo.fromPlatform(), _initHive()]);

  // 2. 執行產生的 init (處理依賴性註冊)
  LogService.info('🚀 [DI] Stage 2: Injectable Initialization');
  await getIt.init();

  LogService.info('✅ [DI] Dependencies setup completed.');
}

Future<HiveService> _initHive() async {
  final service = HiveService();
  await service.init();
  return service;
}
