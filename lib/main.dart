import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService().init();

  // Initialize Map Tile Caching
  // Map Tile Caching is handled lazily by MapProvider

  // Setup Dependencies
  await setupDependencies();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const SummitMateApp());
}
