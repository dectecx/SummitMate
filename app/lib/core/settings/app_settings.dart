import 'dart:convert';

import '../db/app_database.dart';

/// Small key/value settings stored in the database (replaces SharedPreferences).
class SettingsStore {
  SettingsStore(this._db);
  final AppDatabase _db;

  static const welcomeSeen = 'welcome_seen';
  static const seenHints = 'seen_hints';
  static const themeMode = 'theme_mode';

  Future<String?> get(String key) async =>
      (await (_db.select(_db.appSettings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watch(String key) =>
      (_db.select(_db.appSettings)..where((s) => s.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<void> set(String key, String value) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) => (_db.delete(_db.appSettings)..where((s) => s.key.equals(key))).go();

  Future<bool> getBool(String key) async => (await get(key)) == 'true';
  Future<void> setBool(String key, bool v) => set(key, v ? 'true' : 'false');

  // ---- onboarding hints: each is shown once, then remembered

  Future<Set<String>> _hints() async {
    final raw = await get(seenHints);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<bool> hasSeenHint(String id) async => (await _hints()).contains(id);

  Future<void> markHintSeen(String id) async => set(seenHints, jsonEncode(((await _hints())..add(id)).toList()..sort()));
}
