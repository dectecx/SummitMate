// End-to-end check of the auth client and token refresh against a running backend.
// Skipped unless E2E_BASE_URL and E2E_BACKEND_LOG (the backend's log file, where the development
// mailer prints verification codes) are set. See backend/README.md.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/auth/auth_api.dart';
import 'package:summitmate/core/auth/auth_interceptor.dart';
import 'package:summitmate/core/auth/auth_repository.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/local_account.dart';
import 'package:summitmate/core/sync/dio_sync_api.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_engine.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import '../core/support.dart';

String codeFor(String logPath, String email) {
  final lines = File(logPath).readAsLinesSync().where((l) => l.contains('to=$email'));
  return RegExp(r'code=(\d{6})').firstMatch(lines.last)!.group(1)!;
}

void main() {
  final baseUrl = Platform.environment['E2E_BASE_URL'];
  final logPath = Platform.environment['E2E_BACKEND_LOG'];
  final enabled = baseUrl != null && logPath != null;

  test('guest data uploads after sign-up; refresh, password change and revoked sessions behave', () async {
    final email = 'e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    final db = memoryDb();
    final writer = OutboxWriter(db);
    final tokens = MemoryTokenStore();
    final publicDio = Dio(BaseOptions(baseUrl: baseUrl!));
    final authedDio = Dio(BaseOptions(baseUrl: baseUrl));
    late final AuthRepository repo;
    repo = AuthRepository(
      api: DioAuthApi(publicDio: publicDio, authedDio: authedDio),
      tokens: tokens,
      account: LocalAccountStore(db),
    );
    authedDio.interceptors.add(AuthInterceptor(tokens: repo, dio: authedDio));
    final engine = SyncEngine(db: db, api: DioSyncApi(authedDio), gate: repo, onAuthFailure: repo.markNeedsReauth);
    addTearDown(() async {
      await engine.dispose();
      await repo.dispose();
      await db.close();
    });

    // 1. A guest plans a trip offline. Nothing syncs.
    await repo.restore();
    expect(repo.state, isA<Guest>());
    await localCreate(db, writer, tripsEntity, tripRow('11111111-1111-4111-8111-111111111111', name: 'Guest trip'));
    expect(await engine.sync(), SyncOutcome.skipped);

    // 2. Sign up, verify, and the guest trip uploads.
    await repo.register(email: email, password: 'Passw0rdX', displayName: 'E2E');
    await expectLater(repo.login(email: email, password: 'Passw0rdX'), throwsA(isA<AuthException>().having((e) => e.code, 'code', 'email_not_verified')));
    await expectLater(repo.verifyEmail(email: email, code: '000000'), throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid_verification_code')));
    final signedIn = await repo.verifyEmail(email: email, code: codeFor(logPath!, email));
    expect(signedIn.discardedLocalData, isFalse);
    expect(await engine.sync(), SyncOutcome.success);
    expect(await opSummary(db), isEmpty);
    expect((await select(db, 'SELECT owner_id FROM trips')).single['owner_id'], signedIn.user.id);

    // 3. An expired/invalid access token is refreshed transparently.
    final before = (await tokens.read())!;
    await tokens.write(StoredTokens(access: 'not-a-valid-token', refresh: before.refresh));
    await localEdit(db, writer, tripsEntity, '11111111-1111-4111-8111-111111111111', {'name': 'Renamed'});
    expect(await engine.sync(), SyncOutcome.success);
    final after = (await tokens.read())!;
    expect(after.refresh, isNot(before.refresh), reason: 'refresh tokens rotate');
    expect(after.access, isNot('not-a-valid-token'));
    expect(repo.state, isA<SignedIn>());

    // 4. Changing the password revokes all refresh tokens; the client signs in again by itself.
    await repo.changePassword(current: 'Passw0rdX', next: 'NewPassw0rdY');
    await localEdit(db, writer, tripsEntity, '11111111-1111-4111-8111-111111111111', {'description': 'after password change'});
    await tokens.write(StoredTokens(access: 'stale', refresh: (await tokens.read())!.refresh));
    expect(await engine.sync(), SyncOutcome.success);

    // 5. A revoked session ends syncing but never touches local data.
    final session = (await tokens.read())!;
    await publicDio.post<Object?>('/auth/logout', data: {'refresh_token': session.refresh}); // revoked elsewhere
    await tokens.write(StoredTokens(access: 'stale', refresh: session.refresh));
    await localEdit(db, writer, tripsEntity, '11111111-1111-4111-8111-111111111111', {'description': 'offline after revoke'});
    expect(await engine.sync(), SyncOutcome.needsReauth);
    expect(repo.state, isA<NeedsReauth>());
    expect(repo.canSync, isFalse);
    expect(await opSummary(db), ['upsert:trips/11111111-1111-4111-8111-111111111111']);
    expect(await engine.sync(), SyncOutcome.skipped);

    // 6. Signing in again as the same person resumes and uploads the waiting edit.
    final again = await repo.login(email: email, password: 'NewPassw0rdY');
    expect(again.discardedLocalData, isFalse);
    expect(await engine.sync(), SyncOutcome.success);
    expect(await opSummary(db), isEmpty);

    // 7. Signing out returns to guest mode and clears the account's data.
    await repo.logout();
    expect(repo.state, isA<Guest>());
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
  }, skip: enabled ? false : 'set E2E_BASE_URL and E2E_BACKEND_LOG');
}
