import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/core/sync/sync_status.dart';

import 'auth_support.dart';
import 'support.dart';

void main() {
  authedWiringTest();
  late AppDatabase db;
  late FakeAuthApi api;
  late ProviderContainer container;

  setUp(() {
    db = memoryDb();
    api = FakeAuthApi()..addAccount('a@x.co', 'Passw0rd1');
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        authApiProvider.overrideWithValue(api),
        connectivityOnlineProvider.overrideWith((ref) => const Stream<bool>.empty()),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('the sync status follows sign-in, queued changes and failures', () async {
    final repo = container.read(authRepositoryProvider);
    final writer = container.read(outboxWriterProvider);
    final seen = <SyncStatus>[];
    container.listen(syncStatusProvider, (_, s) => seen.add(s), fireImmediately: true);
    await repo.restore();
    await pumpEventQueue();
    expect(container.read(syncStatusProvider), isA<GuestLocalOnly>());

    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await repo.login(email: 'a@x.co', password: 'Passw0rd1');
    await pumpEventQueue();
    expect(container.read(syncStatusProvider), isA<Pending>().having((p) => p.count, 'count', 1));

    // Uploaded: nothing left.
    await db.delete(db.outbox).go();
    await pumpEventQueue();
    expect(container.read(syncStatusProvider), isA<Synced>());

    repo.markNeedsReauth();
    await pumpEventQueue();
    expect(container.read(syncStatusProvider), isA<SessionExpired>());
    expect(container.read(authStateProvider).value, isA<NeedsReauth>());
  });

  test('the engine only syncs for a valid session', () async {
    final repo = container.read(authRepositoryProvider);
    final engine = container.read(syncEngineProvider);
    await repo.restore();
    expect(await engine.sync(), isNot(equals(null)));
    expect(repo.canSync, isFalse);
  });
}

/// Regression test: the authenticated Dio, the auth repository and the sync API depend on each
/// other through the session bridge; wiring them with provider reads once failed at request time.
void authedWiringTest() {
  test('the real authenticated Dio sends the stored access token and refreshes on 401', () async {
    final db = memoryDb();
    final tokens = MemoryTokenStore();
    final api = FakeAuthApi()..addAccount('a@x.co', 'Passw0rd1');
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tokenStoreProvider.overrideWithValue(tokens),
        authApiProvider.overrideWithValue(api),
        connectivityOnlineProvider.overrideWith((ref) => const Stream<bool>.empty()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final repo = container.read(authRepositoryProvider);
    await repo.login(email: 'a@x.co', password: 'Passw0rd1'); // stores access-1 / refresh-1

    final seen = <String?>[];
    final adapter = ScriptedAdapter((req) async {
      seen.add(req.headers['Authorization'] as String?);
      if (req.headers['Authorization'] == 'Bearer access-2') {
        return json({'server_time': 'x', 'next_since': 'y', 'has_more': false, 'changes': {}});
      }
      return json({'code': 'unauthorized'}, 401);
    });
    container.read(authedDioProvider).httpClientAdapter = adapter;

    final page = await container.read(syncApiProvider).pull(limit: 1);

    expect(page.nextSince, 'y');
    expect(seen, ['Bearer access-1', 'Bearer access-2'], reason: 'first token rejected, refreshed, replayed');
    expect(api.refreshCalls, 1);
  });
}
