import 'package:drift/drift.dart';

import '../auth/auth_state.dart';
import 'app_database.dart';

/// Ties the local database to one account (or to nobody, for a guest).
class LocalAccountStore {
  LocalAccountStore(this._db);
  final AppDatabase _db;

  Future<AppMetaData> read() => (_db.select(_db.appMeta)..where((m) => m.id.equals(1))).getSingle();

  Stream<AppMetaData> watch() => (_db.select(_db.appMeta)..where((m) => m.id.equals(1))).watchSingle();

  /// Call after a successful sign-in. Returns true if existing local data had to be wiped
  /// because it belonged to a different account.
  ///
  /// Guest data (no account yet) is adopted: it stays in place and the outbox uploads it.
  Future<bool> onSignedIn(AuthUser user) => _db.transaction(() async {
    final meta = await read();
    final differentAccount = meta.accountId != null && meta.accountId != user.id;
    if (differentAccount) await resetLocalData();
    await (_db.update(_db.appMeta)..where((m) => m.id.equals(1))).write(
      AppMetaCompanion(
        accountId: Value(user.id),
        email: Value(user.email),
        displayName: Value(user.displayName),
        avatar: Value(user.avatar),
      ),
    );
    return differentAccount;
  });

  /// Wipes everything that belongs to an account (trips and their content, the outbox, the
  /// sync cursor, the profile). App settings are kept. Used on sign-out and account switch.
  Future<void> resetLocalData() => _db.transaction(() async {
    await _db.delete(_db.trips).go(); // children cascade
    await _db.delete(_db.libraryItems).go();
    await _db.delete(_db.templates).go();
    await _db.delete(_db.outbox).go();
    await (_db.update(_db.appMeta)..where((m) => m.id.equals(1))).write(
      const AppMetaCompanion(
        accountId: Value(null),
        syncCursor: Value(null),
        lastSyncedAt: Value(null),
        email: Value(null),
        displayName: Value(null),
        avatar: Value(null),
      ),
    );
    // Cascades are invisible to Drift; refresh listeners of the child tables.
    _db.notifyUpdates({
      for (final t in <TableInfo<Table, dynamic>>[_db.tripMembers, _db.itineraryItems, _db.gearItems, _db.mealPlanDays, _db.mealItems, _db.libraryItems, _db.templates])
        TableUpdate.onTable(t, kind: UpdateKind.delete),
    });
  });

  /// Number of operations that have not reached the server (pending or failed).
  Future<int> unsyncedCount() async => (await _db.select(_db.outbox).get()).length;
}
