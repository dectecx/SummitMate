import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/di.dart';
import 'infrastructure/tools/hive_service.dart';
import 'infrastructure/observers/global_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService().init();

  // Initialize Map Tile Caching (Android/iOS only)
  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
  }

  // Setup Dependencies
  try {
    await setupDependencies();
  } catch (e, stackTrace) {
    debugPrint('DI Setup Failed: $e');
    debugPrintStack(stackTrace: stackTrace);
    // Continue or exit? Continuing might cause crashes later.
  }

  // Setup Global Bloc Observer
  Bloc.observer = GlobalBlocObserver();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Log to Crashlytics or LogService
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const SummitMateApp());
}
