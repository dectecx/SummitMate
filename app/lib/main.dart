import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'infrastructure/observers/global_bloc_observer.dart';
import 'infrastructure/tools/log_service.dart';
import 'infrastructure/database/database_migration_manager.dart';

Future<void> main() async {
  // ① Web: remove '#' from URL path
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();

  // ② Locale data
  await initializeDateFormatting('zh_TW', null);

  // ③ Global Bloc observer
  Bloc.observer = GlobalBlocObserver();

  // ④ Global Flutter framework error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LogService.error('Flutter Error: ${details.exception}', source: 'Global (main)', stackTrace: details.stack);
  };

  // ⑤ Catch uncaught async errors (Future / Stream)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LogService.error('Uncaught async error: $error', source: 'PlatformDispatcher', stackTrace: stack);
    return true; // error handled
  };

  // ⑥ 啟動輕量引導 UI (SplashApp) 以顯示資料庫遷移進度
  final progress = ValueNotifier<double>(0.0);
  final message = ValueNotifier<String>('正在初始化應用程式...');
  runApp(SplashApp(progress: progress, message: message));

  // ⑦ Setup DI & Database Migration
  try {
    progress.value = 0.1;
    message.value = '正在載入系統設定...';
    final prefs = await SharedPreferences.getInstance();

    final migrationManager = DatabaseMigrationManager(prefs);
    await migrationManager.checkAndMigrate(
      currentVersion: 1, // 目前資料庫 Schema 版本
      onProgress: (p, msg) {
        // 將遷移進度映射在 0.1 ~ 0.8 之間
        progress.value = 0.1 + (p * 0.7);
        message.value = msg;
      },
    );

    progress.value = 0.85;
    message.value = '載入核心模組與依賴...';
    await configureDependencies();

    progress.value = 0.9;
    message.value = '正在完成最後初始化...';
    await LogService.init();

    // Map tile caching is not supported on Web
    if (!kIsWeb) {
      await FMTCObjectBoxBackend().initialise();
    }

    progress.value = 1.0;
    message.value = '初始化完成';
    await Future.delayed(const Duration(milliseconds: 200));

    runApp(const SummitMateApp());
  } catch (e, stackTrace) {
    debugPrint('App startup failed: $e\n$stackTrace');
    runApp(InitializationErrorApp(error: e.toString()));
  }
}

/// Simple error UI displayed when the app fails to initialise.
class InitializationErrorApp extends StatelessWidget {
  final String error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 80),
                const SizedBox(height: 24),
                const Text(
                  '應用程式初始化失敗',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  '這可能是由於資料庫損壞或權限不足導致。請嘗試重新啟動應用程式。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '錯誤詳情: $error',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SplashApp 顯示極致外觀的開機引導畫面與資料庫升級/快取優化進度
class SplashApp extends StatelessWidget {
  final ValueNotifier<double> progress;
  final ValueNotifier<String> message;

  const SplashApp({super.key, required this.progress, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E7D32), // Forest Green
                Color(0xFF1B5E20), // Jungle Green
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 圓形發光的山岳 icon
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF9A825).withValues(alpha: 0.3), // Sunny Gold glow
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.terrain_rounded,
                      color: Color(0xFFF9A825), // Sunny Gold
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SummitMate',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '山岳夥伴 • 安全同行',
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 64),
                  ValueListenableBuilder2<double, String>(
                    listenable1: progress,
                    listenable2: message,
                    builder: (context, p, msg, _) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 6,
                              width: 240,
                              child: LinearProgressIndicator(
                                value: p,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF9A825)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            msg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(p * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF9A825).withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 用於同時監聽兩個 ValueListenable 的輔助 Widget
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> listenable1;
  final ValueListenable<B> listenable2;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.listenable1,
    required this.listenable2,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: listenable1,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: listenable2,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}
