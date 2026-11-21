// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import '../db/local_account.dart';
import '../sync/sync_engine.dart';
import 'auth_api.dart';
import 'auth_interceptor.dart';
import 'auth_state.dart';
import 'token_store.dart';

/// Signing out would lose changes that never reached the server.
class UnsyncedChangesException implements Exception {
  const UnsyncedChangesException(this.count);
  final int count;
  @override
  String toString() => 'UnsyncedChangesException($count)';
}

/// Result of a successful sign-in.
class SignInResult {
  const SignInResult({required this.user, required this.discardedLocalData});
  final AuthUser user;

  /// True when the device held another account's data, which was wiped.
  final bool discardedLocalData;
}

/// Owns "who is using the app": the [AuthState], the tokens, and the link between the signed-in
/// account and the local database. Implements [SyncGate]: only a valid session syncs.
class AuthRepository implements SyncGate, TokenSource {
  AuthRepository({required AuthApi api, required TokenStore tokens, required LocalAccountStore account})
    : _api = api,
      _tokens = tokens,
      _account = account;

  final AuthApi _api;
  final TokenStore _tokens;
  final LocalAccountStore _account;

  AuthState _state = const Guest();
  final _changes = StreamController<AuthState>.broadcast();
  Future<String?>? _refreshing;

  AuthState get state => _state;

  @override
  bool get canSync => _state is SignedIn;

  /// Emits the current state first, then every change.
  Stream<AuthState> watch() async* {
    yield _state;
    yield* _changes.stream;
  }

  void _emit(AuthState s) {
    _state = s;
    _changes.add(s);
  }

  /// Decides the initial state from what is stored. Call once at startup, before sync.
  Future<void> restore() async {
    final tokens = await _tokens.read();
    final meta = await _account.read();
    final accountId = meta.accountId;
    if (accountId == null) {
      // Keychain items survive an app reinstall; tokens without a local account are leftovers.
      if (tokens != null) await _tokens.clear();
      _emit(const Guest());
      return;
    }
    final user = AuthUser(id: accountId, email: meta.email ?? '', displayName: meta.displayName ?? '', avatar: meta.avatar ?? '');
    _emit(tokens == null ? NeedsReauth(user) : SignedIn(user));
  }

  // ---------------------------------------------------------------- sign in

  /// Creates an account. The person must then verify the email with [verifyEmail].
  Future<void> register({required String email, required String password, required String displayName, String? avatar}) =>
      _api.register(email: email, password: password, displayName: displayName, avatar: avatar);

  Future<void> resendVerification(String email) => _api.resendVerification(email);

  Future<SignInResult> verifyEmail({required String email, required String code}) async =>
      _completeSignIn(await _api.verifyEmail(email: email, code: code));

  Future<SignInResult> login({required String email, required String password}) async =>
      _completeSignIn(await _api.login(email: email, password: password));

  Future<SignInResult> _completeSignIn(AuthSession session) async {
    // Local data first: if the app dies between the steps, the next start sees an account
    // without tokens and asks to sign in again, instead of tokens for the wrong data.
    final discarded = await _account.onSignedIn(session.user);
    await _tokens.write(StoredTokens(access: session.tokens.access, refresh: session.tokens.refresh));
    _emit(SignedIn(session.user));
    return SignInResult(user: session.user, discardedLocalData: discarded);
  }

  // ---------------------------------------------------------------- sign out

  /// Ends the session and returns the device to guest mode (account data is removed; settings stay).
  /// Throws [UnsyncedChangesException] when changes have not reached the server, unless [force].
  Future<void> logout({bool force = false}) async {
    if (!force) {
      final pending = await _account.unsyncedCount();
      if (pending > 0) throw UnsyncedChangesException(pending);
    }
    final tokens = await _tokens.read();
    if (tokens != null) {
      try {
        await _api.logout(tokens.refresh);
      } on Object {
        // Best effort: the local sign-out must work offline.
      }
    }
    await _tokens.clear();
    await _account.resetLocalData();
    _emit(const Guest());
  }

  /// Deactivates the account on the server, then signs out locally.
  Future<void> deleteAccount() async {
    await _api.deleteAccount();
    await logout(force: true);
  }

  // ---------------------------------------------------------------- profile

  Future<void> updateProfile({String? displayName, String? avatar}) async {
    final user = await _api.updateProfile(displayName: displayName, avatar: avatar);
    await _account.onSignedIn(user); // same account: only refreshes the stored profile
    if (_state is SignedIn) _emit(SignedIn(user));
  }

  /// Changes the password. The server then revokes every refresh token, so we sign in again
  /// with the new password to keep this device's session.
  Future<void> changePassword({required String current, required String next}) async {
    final user = _userOrThrow();
    await _api.changePassword(current: current, next: next);
    final session = await _api.login(email: user.email, password: next);
    await _tokens.write(StoredTokens(access: session.tokens.access, refresh: session.tokens.refresh));
  }

  AuthUser _userOrThrow() => switch (_state) {
    SignedIn(:final user) || NeedsReauth(:final user) => user,
    Guest() => throw StateError('not signed in'),
  };

  // ---------------------------------------------------------------- tokens

  @override
  Future<String?> accessToken() async => (await _tokens.read())?.access;

  /// Gets a new access token with the stored refresh token. Concurrent callers share one request.
  /// Returns null when the session is over (the state becomes [NeedsReauth]).
  /// Throws [AuthNetworkException] when the server could not be reached; the session is kept.
  @override
  Future<String?> refreshAccessToken() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final stored = await _tokens.read();
    if (stored == null) {
      markNeedsReauth();
      return null;
    }
    try {
      final fresh = await _api.refresh(stored.refresh);
      await _tokens.write(StoredTokens(access: fresh.access, refresh: fresh.refresh));
      return fresh.access;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        markNeedsReauth();
        return null;
      }
      rethrow;
    }
  }

  /// The server no longer accepts our session. Keep working locally; pause syncing.
  void markNeedsReauth() {
    if (_state case SignedIn(:final user)) _emit(NeedsReauth(user));
  }

  Future<void> dispose() => _changes.close();
}
