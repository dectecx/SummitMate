import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/auth/token_store.dart';
import 'core/db/app_database.dart';
import 'core/providers.dart';
import 'core/settings/app_settings.dart';
import 'features/map/data/tile_cache.dart';
import 'features/map/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await buildApp());
}

/// Builds the app widget: restores the session, starts the sync triggers and picks the first screen.
/// The parameters let integration tests run the real app on an in-memory database and a fake keychain.
Future<Widget> buildApp({AppDatabase? database, TokenStore? tokens, String? apiBaseUrl, TileCache? tileCache}) async {
  final cache = tileCache ?? await FmtcTileCache.initialise();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database ?? AppDatabase.open()),
      tileCacheProvider.overrideWithValue(cache),
      if (tokens != null) tokenStoreProvider.overrideWithValue(tokens),
      if (apiBaseUrl != null) apiBaseUrlProvider.overrideWithValue(apiBaseUrl),
    ],
  );

  // Who is using the app must be known before anything syncs.
  await container.read(authRepositoryProvider).restore();
  container.read(syncCoordinatorProvider); // starts listening for sync triggers
  await container.read(offlineManagerProvider).recover(); // downloads cut off by the last shutdown

  final welcomeSeen = await container.read(settingsStoreProvider).getBool(SettingsStore.welcomeSeen);
  return UncontrolledProviderScope(
    container: container,
    child: SummitMateApp(initialLocation: welcomeSeen ? Routes.trips : Routes.welcome),
  );
}
