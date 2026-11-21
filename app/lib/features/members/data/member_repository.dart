// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/member_logic.dart';

/// Membership changes. They are applied locally at once and uploaded by the sync engine; the server
/// has the final say (permissions are checked there).
class MemberRepository {
  MemberRepository(this._db, this._outbox);
  final AppDatabase _db;
  final OutboxWriter _outbox;

  /// Adds [user] to the trip. [role] is `guide` or `member`.
  Future<void> invite(String tripId, FoundUser user, {String role = 'member'}) async {
    assert(role == 'guide' || role == 'member');
    final id = memberIdFor(tripId, user.id);
    await _db.transaction(() async {
      await _db.into(_db.tripMembers).insertOnConflictUpdate(
        TripMembersCompanion.insert(id: id, tripId: tripId, userId: user.id, role: Value(role), displayName: Value(user.displayName), avatar: Value(user.avatar)),
      );
      await _outbox.upsert('trip_members', id, {'trip_id': tripId, 'user_id': user.id, 'role': role}, isCreate: true);
    });
  }

  Future<void> setRole(String tripId, String userId, String role) async {
    assert(role == 'guide' || role == 'member');
    final id = memberIdFor(tripId, userId);
    await _db.transaction(() async {
      await (_db.update(_db.tripMembers)..where((m) => m.id.equals(id))).write(TripMembersCompanion(role: Value(role)));
      await _outbox.upsert('trip_members', id, {'role': role});
    });
  }

  Future<void> remove(String tripId, String userId) async {
    final id = memberIdFor(tripId, userId);
    await _db.transaction(() async {
      await _outbox.delete('trip_members', id);
      await (_db.delete(_db.tripMembers)..where((m) => m.id.equals(id))).go();
    });
  }

  /// Leaves a trip that someone else owns: the trip disappears from this device and the server is told.
  Future<void> leave(String tripId, String myUserId) async {
    final id = memberIdFor(tripId, myUserId);
    await _db.transaction(() async {
      await _outbox.dropTripWork(tripId);
      await _outbox.delete('trip_members', id);
      await (_db.delete(_db.trips)..where((t) => t.id.equals(tripId))).go();
    });
  }
}
