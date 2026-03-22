import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'infrastructure/observers/global_bloc_observer.dart';
import 'infrastructure/tools/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Locale Data
  await initializeDateFormatting('zh_TW', null);

  // Setup Dependencies (Injectable)
  try {
    await configureDependencies();
  } catch (e, stackTrace) {
    debugPrint('DI Setup Failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Initialize Map Tile Caching (Android/iOS only)
  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
  }

  // Setup Global Bloc Observer
  Bloc.observer = GlobalBlocObserver();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LogService.error('Flutter Error: ${details.exception}', source: 'Global (main)', stackTrace: details.stack);
  };

  runApp(const SummitMateApp());
}
