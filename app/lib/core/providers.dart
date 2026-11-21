import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_api.dart';
import 'auth/auth_interceptor.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_state.dart';
import 'auth/token_store.dart';
import 'config.dart';
import 'db/app_database.dart';
import 'db/local_account.dart';
import 'settings/app_settings.dart';
import 'sync/connectivity.dart';
import 'sync/dio_sync_api.dart';
import 'sync/outbox_counts.dart';
import 'sync/outbox_writer.dart';
import 'sync/sync_api.dart';
import 'sync/sync_coordinator.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_status.dart';

/// Overridden in `main()` with the opened database (and with a memory database in tests).
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override appDatabaseProvider'));

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
final apiBaseUrlProvider = Provider<String>((ref) => AppConfig.apiBaseUrl);

final localAccountStoreProvider = Provider((ref) => LocalAccountStore(ref.watch(appDatabaseProvider)));
final settingsStoreProvider = Provider((ref) => SettingsStore(ref.watch(appDatabaseProvider)));
final outboxWriterProvider = Provider((ref) => OutboxWriter(ref.watch(appDatabaseProvider)));

BaseOptions _dioOptions(String baseUrl) => BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Accept': 'application/json'},
);

/// Dio for calls that must never carry or refresh a token (login, refresh, ...).
final publicDioProvider = Provider<Dio>((ref) => Dio(_dioOptions(ref.watch(apiBaseUrlProvider))));

/// Dio that adds the access token and refreshes it on 401.
final Provider<Dio> authedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_dioOptions(ref.watch(apiBaseUrlProvider)));
  // Read lazily: the repository itself depends on this Dio through the API object.
  dio.interceptors.add(AuthInterceptor(tokens: _LazyTokenSource(() => ref.read(authRepositoryProvider)), dio: dio));
  return dio;
});

final Provider<AuthApi> authApiProvider = Provider<AuthApi>(
  (ref) => DioAuthApi(publicDio: ref.watch(publicDioProvider), authedDio: ref.watch(authedDioProvider)),
);

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository(api: ref.watch(authApiProvider), tokens: ref.watch(tokenStoreProvider), account: ref.watch(localAccountStoreProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Who is using the app. Call `authRepositoryProvider.restore()` once at startup before reading it.
final authStateProvider = StreamProvider<AuthState>((ref) => ref.watch(authRepositoryProvider).watch());

final syncApiProvider = Provider<SyncApi>((ref) => DioSyncApi(ref.watch(authedDioProvider)));

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final engine = SyncEngine(db: ref.watch(appDatabaseProvider), api: ref.watch(syncApiProvider), gate: auth, onAuthFailure: auth.markNeedsReauth);
  ref.onDispose(engine.dispose);
  return engine;
});

final outboxCountsProvider = StreamProvider<OutboxCounts>((ref) => watchOutboxCounts(ref.watch(appDatabaseProvider)));
final syncRunningProvider = StreamProvider<bool>((ref) => ref.watch(syncEngineProvider).running);

/// Connectivity hint from the platform (null until the first event); not proof the server is reachable.
final connectivityOnlineProvider = StreamProvider<bool>((ref) => watchOnline());

/// Whether the device appears to have a connection. Assumes online until the platform reports.
final onlineProvider = Provider<bool>((ref) => ref.watch(connectivityOnlineProvider).value ?? true);

/// Fires when the app returns to the foreground. Override in tests.
final appResumedProvider = Provider<Stream<void>>((ref) {
  final observer = AppResumedObserver();
  ref.onDispose(observer.dispose);
  return observer.resumed;
});

/// Starts the sync triggers. Read it once at startup (after `authRepositoryProvider.restore()`);
/// `ref.read(syncCoordinatorProvider).refresh()` is the pull-to-refresh entry point.
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(
    engine: ref.watch(syncEngineProvider),
    auth: ref.watch(authRepositoryProvider).watch(),
    outbox: watchOutboxCounts(ref.watch(appDatabaseProvider)),
    online: watchOnline(),
    resumed: ref.watch(appResumedProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// The single value the UI shows about syncing.
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final counts = ref.watch(outboxCountsProvider).value ?? (pending: 0, failed: 0);
  return computeSyncStatus(
    auth: ref.watch(authStateProvider).value ?? ref.watch(authRepositoryProvider).state,
    pending: counts.pending,
    failed: counts.failed,
    syncing: ref.watch(syncRunningProvider).value ?? false,
    online: ref.watch(onlineProvider),
  );
});

class _LazyTokenSource implements TokenSource {
  _LazyTokenSource(this._get);
  final TokenSource Function() _get;
  @override
  Future<String?> accessToken() => _get().accessToken();
  @override
  Future<String?> refreshAccessToken() => _get().refreshAccessToken();
}
