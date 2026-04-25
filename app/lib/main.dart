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

void main() async {
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Locale Data
  await initializeDateFormatting('zh_TW', null);

  // Setup Global Bloc Observer
  Bloc.observer = GlobalBlocObserver();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LogService.error('Flutter Error: ${details.exception}', source: 'Global (main)', stackTrace: details.stack);
  };

  // Setup Dependencies (Injectable)
  try {
    await configureDependencies();

    // Initialize Map Tile Caching (Android/iOS only)
    if (!kIsWeb) {
      await FMTCObjectBoxBackend().initialise();
    }

    runApp(const SummitMateApp());
  } catch (e, stackTrace) {
    debugPrint('DI Setup Failed: $e');
    debugPrintStack(stackTrace: stackTrace);

    // Fail Fast: Show Error UI
    runApp(InitializationErrorApp(error: e.toString()));
  }
}

/// 啟動初始化失敗時顯示的簡單介面
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
