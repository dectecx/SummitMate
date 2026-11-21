import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/auth/auth_api.dart';
import 'package:summitmate/core/auth/auth_repository.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/db/local_account.dart';
import 'package:summitmate/core/settings/app_settings.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import 'auth_support.dart';
import 'support.dart';

void main() {
  late AppDatabase db;
  late FakeAuthApi api;
  late MemoryTokenStore tokens;
  late LocalAccountStore account;
  late OutboxWriter writer;
  late AuthRepository repo;

  setUp(() {
    db = memoryDb();
    api = FakeAuthApi();
    tokens = MemoryTokenStore();
    account = LocalAccountStore(db);
    writer = OutboxWriter(db);
    repo = AuthRepository(api: api, tokens: tokens, account: account);
  });
  tearDown(() async {
    await repo.dispose();
    await db.close();
  });

  group('restore', () {
    test('a fresh install is a guest', () async {
      await repo.restore();
      expect(repo.state, isA<Guest>());
      expect(repo.canSync, isFalse);
    });

    test('stored tokens with a local account resume the session', () async {
      await account.onSignedIn(api.addAccount('a@x.co', 'Passw0rd1'));
      await tokens.write(const StoredTokens(access: 'a', refresh: 'r'));
      await repo.restore();
      expect((repo.state as SignedIn).user.email, 'a@x.co');
      expect(repo.canSync, isTrue);
    });

    test('tokens left in the keychain after a reinstall are discarded', () async {
      await tokens.write(const StoredTokens(access: 'a', refresh: 'r'));
      await repo.restore();
      expect(repo.state, isA<Guest>());
      expect(await tokens.read(), isNull);
    });

    test('an account without tokens needs to sign in again but keeps its data', () async {
      await account.onSignedIn(api.addAccount('a@x.co', 'Passw0rd1'));
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      await repo.restore();
      expect(repo.state, isA<NeedsReauth>());
      expect(repo.canSync, isFalse);
      expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
    });
  });

  group('sign in', () {
    setUp(() async {
      api.addAccount('a@x.co', 'Passw0rd1', name: 'Alice');
      await repo.restore();
    });

    test('login stores tokens, adopts guest data and keeps its pending uploads', () async {
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      final states = <AuthState>[];
      final sub = repo.watch().listen(states.add);

      final result = await repo.login(email: 'a@x.co', password: 'Passw0rd1');

      await pumpEventQueue();
      await sub.cancel();
      expect(result.discardedLocalData, isFalse);
      expect(states.map((s) => s.runtimeType), [Guest, SignedIn]);
      expect((await tokens.read())!.access, 'access-1');
      expect((await account.read()).accountId, 'id-a');
      expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
      expect(await opSummary(db), ['upsert:trips/t1']);
      expect(repo.canSync, isTrue);
    });

    test('a wrong password leaves everything as it was', () async {
      await expectLater(
        repo.login(email: 'a@x.co', password: 'nope'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid_credentials')),
      );
      expect(repo.state, isA<Guest>());
      expect(await tokens.read(), isNull);
      expect((await account.read()).accountId, isNull);
    });

    test('register then verify signs in', () async {
      await repo.register(email: 'new@x.co', password: 'Passw0rd1', displayName: 'New');
      expect(repo.state, isA<Guest>(), reason: 'registering alone does not sign in');
      await expectLater(repo.verifyEmail(email: 'new@x.co', code: '000000'), throwsA(isA<AuthException>()));
      expect(repo.state, isA<Guest>());

      await repo.verifyEmail(email: 'new@x.co', code: api.lastCode);
      expect((repo.state as SignedIn).user.email, 'new@x.co');
    });

    test('signing in as a different account after a lost session wipes the old data', () async {
      api.addAccount('b@x.co', 'Passw0rd1');
      await repo.login(email: 'a@x.co', password: 'Passw0rd1');
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      repo.markNeedsReauth();
      expect(repo.state, isA<NeedsReauth>());

      final result = await repo.login(email: 'b@x.co', password: 'Passw0rd1');

      expect(result.discardedLocalData, isTrue);
      expect(await select(db, 'SELECT id FROM trips'), isEmpty);
      expect(await opSummary(db), isEmpty);
      expect((repo.state as SignedIn).user.email, 'b@x.co');
    });

    test('signing in again as the same account after a lost session keeps the data', () async {
      await repo.login(email: 'a@x.co', password: 'Passw0rd1');
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      repo.markNeedsReauth();
      final result = await repo.login(email: 'a@x.co', password: 'Passw0rd1');
      expect(result.discardedLocalData, isFalse);
      expect(await opSummary(db), ['upsert:trips/t1']);
    });
  });

  group('sign out', () {
    setUp(() async {
      api.addAccount('a@x.co', 'Passw0rd1');
      await repo.restore();
      await repo.login(email: 'a@x.co', password: 'Passw0rd1');
    });

    test('is refused while changes are waiting to upload, unless forced', () async {
      await SettingsStore(db).setBool(SettingsStore.welcomeSeen, true);
      await localCreate(db, writer, tripsEntity, tripRow('t1'));

      await expectLater(repo.logout(), throwsA(isA<UnsyncedChangesException>().having((e) => e.count, 'count', 1)));
      expect(repo.state, isA<SignedIn>());
      expect(await tokens.read(), isNotNull);
      expect(await select(db, 'SELECT id FROM trips'), hasLength(1));

      await repo.logout(force: true);
      expect(repo.state, isA<Guest>());
      expect(await tokens.read(), isNull);
      expect(await select(db, 'SELECT id FROM trips'), isEmpty);
      expect((await account.read()).accountId, isNull);
      expect(await SettingsStore(db).getBool(SettingsStore.welcomeSeen), isTrue, reason: 'settings survive sign-out');
      expect(api.logoutTokens, ['refresh-1']);
    });

    test('works offline: a failing server call does not block signing out', () async {
      api.logoutError = const AuthNetworkException();
      await repo.logout();
      expect(repo.state, isA<Guest>());
      expect(await tokens.read(), isNull);
    });

    test('deleting the account signs out locally too', () async {
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      await repo.deleteAccount();
      expect(api.deleted, isTrue);
      expect(repo.state, isA<Guest>());
      expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    });
  });

  group('token refresh', () {
    setUp(() async {
      api.addAccount('a@x.co', 'Passw0rd1');
      await repo.restore();
      await repo.login(email: 'a@x.co', password: 'Passw0rd1');
    });

    test('concurrent callers share one refresh and the new pair is stored', () async {
      final gate = api.refreshGate = Completer<void>();
      final futures = [for (var i = 0; i < 5; i++) repo.refreshAccessToken()];
      gate.complete();
      final results = await Future.wait(futures);

      expect(api.refreshCalls, 1);
      expect(results.toSet(), {'access-2'});
      expect(await tokens.read(), isA<StoredTokens>().having((t) => t.refresh, 'refresh', 'refresh-2'));
      expect(api.refreshTokensSeen, ['refresh-1']);
    });

    test('a rejected refresh token ends the session but keeps local data', () async {
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      api.refreshError = const AuthException(status: 401, code: 'invalid_refresh_token');

      expect(await repo.refreshAccessToken(), isNull);

      expect(repo.state, isA<NeedsReauth>());
      expect(repo.canSync, isFalse);
      expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
    });

    test('being offline during a refresh keeps the session', () async {
      api.refreshError = const AuthNetworkException();
      await expectLater(repo.refreshAccessToken(), throwsA(isA<AuthNetworkException>()));
      expect(repo.state, isA<SignedIn>());
      expect((await tokens.read())!.refresh, 'refresh-1');

      // The next attempt works again.
      api.refreshError = null;
      expect(await repo.refreshAccessToken(), 'access-2');
    });

    test('a server error other than 401 is not mistaken for a lost session', () async {
      api.refreshError = const AuthException(status: 500, code: 'internal_error');
      await expectLater(repo.refreshAccessToken(), throwsA(isA<AuthException>()));
      expect(repo.state, isA<SignedIn>());
    });
  });

  group('profile and password', () {
    setUp(() async {
      api.addAccount('a@x.co', 'Passw0rd1', name: 'Alice');
      await repo.restore();
      await repo.login(email: 'a@x.co', password: 'Passw0rd1');
    });

    test('updating the profile refreshes the stored profile and the state', () async {
      await repo.updateProfile(displayName: 'Alice B');
      expect((repo.state as SignedIn).user.displayName, 'Alice B');
      expect((await account.read()).displayName, 'Alice B');
    });

    test('changing the password signs in again with the new one so the session survives', () async {
      await repo.changePassword(current: 'Passw0rd1', next: 'NewPassw0rd2');

      expect(api.passwordChanges, ['NewPassw0rd2']);
      expect(api.loginCalls, 2);
      expect((await tokens.read())!.access, 'access-2');
      expect(repo.state, isA<SignedIn>());
    });

    test('a wrong current password changes nothing', () async {
      await expectLater(repo.changePassword(current: 'wrong', next: 'NewPassw0rd2'), throwsA(isA<AuthException>()));
      expect(api.loginCalls, 1);
      expect((await tokens.read())!.access, 'access-1');
    });
  });
}
