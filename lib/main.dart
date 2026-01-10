import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'app.dart';
import 'core/di.dart';
import 'infrastructure/tools/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService().init();

  // Initialize Map Tile Caching (Android/iOS only)
  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
  }

  // Setup Dependencies
  await setupDependencies();

  // Placeholderror Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const SummitMateApp());
}
