import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/ads/ads.dart';
import 'core/auth/token_store.dart';
import 'core/db/app_database.dart';
import 'core/providers.dart';
import 'core/settings/app_settings.dart';
import 'dev/dev_config.dart';
import 'shared/brand/splash_overlay.dart';
import 'features/map/data/download_updates.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false); // loads the bar's shaders before the first frame
  final app = await buildApp(ads: true);
  runApp(LiquidGlassWidgets.wrap(child: app, brightnessResolver: Theme.maybeBrightnessOf));
}

/// Builds the app widget: restores the session, starts the sync triggers and picks the first screen.
/// The parameters let integration tests run the real app on an in-memory database and a fake keychain.
Future<Widget> buildApp({AppDatabase? database, TokenStore? tokens, String? apiBaseUrl, bool ads = false, bool? devTools, bool splash = true}) async {
  await DownloadUpdates.resumeFromBackground();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database ?? AppDatabase.open()),
      if (ads && (Platform.isIOS || Platform.isAndroid)) adBannerBuilderProvider.overrideWithValue(initialiseAdMob()),
      splashEnabledProvider.overrideWithValue(splash),
      if (devTools != null) devToolsVisibleProvider.overrideWithValue(devTools),
      if (tokens != null) tokenStoreProvider.overrideWithValue(tokens),
      if (apiBaseUrl != null) apiBaseUrlProvider.overrideWithValue(apiBaseUrl),
    ],
  );

  // Who is using the app must be known before anything syncs.
  await container.read(authRepositoryProvider).restore();
  container.read(syncCoordinatorProvider); // starts listening for sync triggers

  final welcomeSeen = await container.read(settingsStoreProvider).getBool(SettingsStore.welcomeSeen);
  return UncontrolledProviderScope(
    container: container,
    child: SummitMateApp(initialLocation: welcomeSeen ? Routes.trips : Routes.welcome),
  );
}
