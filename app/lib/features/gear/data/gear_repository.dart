// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';

/// The signed-in person's own gear list for a trip (nobody else sees or edits it).
class GearRepository {
  GearRepository(this._db, this._outbox, {Uuid uuid = const Uuid()}) : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final Uuid _uuid;

  Stream<List<GearItem>> watch(String tripId) => (_db.select(_db.gearItems)..where((g) => g.tripId.equals(tripId))).watch();

  /// [weight] is in grams.
  Future<String> add(String tripId, {required String name, double weight = 0, String category = 'other', int quantity = 1}) async {
    final id = _uuid.v7();
    await _db.transaction(() async {
      final last = await (_db.select(_db.gearItems)
            ..where((g) => g.tripId.equals(tripId))
            ..orderBy([(g) => OrderingTerm.desc(g.sortOrder)])
            ..limit(1))
          .getSingleOrNull();
      final order = (last?.sortOrder ?? -1) + 1;
      await _db.into(_db.gearItems).insert(
        GearItemsCompanion.insert(
          id: id,
          tripId: tripId,
          name: Value(name),
          weight: Value(weight),
          category: Value(category),
          quantity: Value(quantity),
          sortOrder: Value(order),
        ),
      );
      await _outbox.upsert(
        'gear_items',
        id,
        {'trip_id': tripId, 'name': name, 'weight': weight, 'category': category, 'quantity': quantity, 'is_checked': false, 'sort_order': order},
        isCreate: true,
      );
    });
    return id;
  }

  /// Changes only the fields that are given.
  Future<void> update(String id, {String? name, double? weight, String? category, int? quantity, bool? isChecked}) async {
    final patch = <String, Object?>{
      'name': ?name,
      'weight': ?weight,
      'category': ?category,
      'quantity': ?quantity,
      'is_checked': ?isChecked,
    };
    if (patch.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.gearItems)..where((g) => g.id.equals(id))).write(
        GearItemsCompanion(
          name: Value.absentIfNull(name),
          weight: Value.absentIfNull(weight),
          category: Value.absentIfNull(category),
          quantity: Value.absentIfNull(quantity),
          isChecked: Value.absentIfNull(isChecked),
        ),
      );
      await _outbox.upsert('gear_items', id, patch);
    });
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('gear_items', id);
    await (_db.delete(_db.gearItems)..where((g) => g.id.equals(id))).go();
  });
}
