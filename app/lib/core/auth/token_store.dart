import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTokens {
  const StoredTokens({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

/// Where the access and refresh tokens live. Tokens never touch the app database.
abstract interface class TokenStore {
  Future<StoredTokens?> read();
  Future<void> write(StoredTokens tokens);
  Future<void> clear();
}

/// Keychain / Keystore backed store.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  static const _access = 'summitmate.access_token';
  static const _refresh = 'summitmate.refresh_token';

  @override
  Future<StoredTokens?> read() async {
    final access = await _s.read(key: _access);
    final refresh = await _s.read(key: _refresh);
    if (access == null || refresh == null) return null;
    return StoredTokens(access: access, refresh: refresh);
  }

  @override
  Future<void> write(StoredTokens t) async {
    await _s.write(key: _access, value: t.access);
    await _s.write(key: _refresh, value: t.refresh);
  }

  @override
  Future<void> clear() async {
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
  }
}

/// For tests and previews.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._tokens]);
  StoredTokens? _tokens;

  @override
  Future<StoredTokens?> read() async => _tokens;
  @override
  Future<void> write(StoredTokens tokens) async => _tokens = tokens;
  @override
  Future<void> clear() async => _tokens = null;
}
