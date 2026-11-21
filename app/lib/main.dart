import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/db/app_database.dart';
import 'core/providers.dart';
import 'core/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(AppDatabase.open())]);

  // Who is using the app must be known before anything syncs.
  await container.read(authRepositoryProvider).restore();
  container.read(syncCoordinatorProvider); // starts listening for sync triggers

  final welcomeSeen = await container.read(settingsStoreProvider).getBool(SettingsStore.welcomeSeen);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: SummitMateApp(initialLocation: welcomeSeen ? Routes.trips : Routes.welcome),
    ),
  );
}
