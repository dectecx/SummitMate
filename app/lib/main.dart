import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'infrastructure/observers/global_bloc_observer.dart';
import 'infrastructure/tools/log_service.dart';

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

  // ⑥ Setup DI & initialise LogService (needs getIt to be ready)
  try {
    await configureDependencies();

    // Initialise LogService now that getIt / LogDao is ready
    await LogService.init();

    // Map tile caching is not supported on Web
    if (!kIsWeb) {
      await FMTCObjectBoxBackend().initialise();
    }

    runApp(const SummitMateApp());
  } catch (e, stackTrace) {
    // Use debugPrint here because LogService.init() may not have completed
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
