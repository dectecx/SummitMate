import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/app/app.dart';
import 'package:summitmate/app/router.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/settings/app_settings.dart';

import '../core/auth_support.dart';
import '../core/support.dart';

/// A running app on an in-memory database with a fake auth server.
class AppHarness {
  AppHarness._(this.db, this.api, this.tokens, this.container);

  final AppDatabase db;
  final FakeAuthApi api;
  final MemoryTokenStore tokens;
  final ProviderContainer container;

  static Future<AppHarness> start(WidgetTester tester, {bool welcomeSeen = false, void Function(FakeAuthApi api)? seed}) async {
    final db = memoryDb();
    final api = FakeAuthApi();
    seed?.call(api);
    final tokens = MemoryTokenStore();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tokenStoreProvider.overrideWithValue(tokens),
        authApiProvider.overrideWithValue(api),
        connectivityOnlineProvider.overrideWith((ref) => const Stream<bool>.empty()),
      ],
    );
    await tester.runAsync(() async {
      await container.read(authRepositoryProvider).restore();
      if (welcomeSeen) await container.read(settingsStoreProvider).setBool(SettingsStore.welcomeSeen, true);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: SummitMateApp(initialLocation: welcomeSeen ? Routes.trips : Routes.welcome),
      ),
    );
    await settle(tester);
    return AppHarness._(db, api, tokens, container);
  }

  Future<void> dispose(WidgetTester tester) async {
    // Unmount, then dispose providers; both cancel database stream subscriptions, whose cleanup
    // runs on (fake) timers. Pump so they fire, otherwise closing the database waits forever.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }
}

/// Lets real asynchronous work (the database) finish, then renders. `pumpAndSettle` alone would
/// wait forever because widget tests run on fake time, which the database does not follow.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Runs [action] on real time (for direct database or repository calls inside a widget test).
Future<T> real<T>(WidgetTester tester, Future<T> Function() action) async => (await tester.runAsync(action)) as T;

Future<void> tapText(WidgetTester tester, String text) async {
  // Prefer a button with this label (the app bar title may use the same words).
  final buttons = find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
  await tester.tap(buttons.evaluate().isNotEmpty ? buttons.last : find.text(text).last);
  await settle(tester);
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), value);
}
