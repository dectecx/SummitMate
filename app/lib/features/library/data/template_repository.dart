// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../gear/data/gear_repository.dart';
import '../../meals/data/meal_repository.dart';
import '../domain/set_item.dart';

/// What applying a template did.
class ApplyResult {
  const ApplyResult({required this.gearAdded, required this.gearSkipped, required this.mealsAdded});
  final int gearAdded;
  final int gearSkipped;
  final int mealsAdded;
}

/// The person's saved templates (a packing list and a meal plan that can be applied to any trip).
class TemplateRepository {
  TemplateRepository(this._db, this._outbox, this._gear, this._meals, {Uuid uuid = const Uuid()}) : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final GearRepository _gear;
  final MealRepository _meals;
  final Uuid _uuid;

  Stream<List<Template>> watchAll() => (_db.select(_db.templates)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch();

  Stream<Template?> watch(String id) => (_db.select(_db.templates)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<String> create({required String title, String note = '', required List<SetItem> items}) async {
    final id = _uuid.v7();
    final encoded = encodeSetItems(items);
    await _db.transaction(() async {
      await _db.into(_db.templates).insert(TemplatesCompanion.insert(id: id, title: Value(title), note: Value(note), items: Value(encoded)));
      await _outbox.upsert('templates', id, {'title': title, 'note': note, 'items': encoded}, isCreate: true);
    });
    return id;
  }

  Future<void> update(String id, {String? title, String? note}) async {
    final patch = <String, Object?>{'title': ?title, 'note': ?note};
    if (patch.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.templates)..where((t) => t.id.equals(id))).write(TemplatesCompanion(title: Value.absentIfNull(title), note: Value.absentIfNull(note)));
      await _outbox.upsert('templates', id, patch);
    });
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('templates', id);
    await (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();
  });

  /// The trip's own gear and meals as template items.
  Future<List<SetItem>> itemsOfTrip(String tripId) async {
    final gear = await (_db.select(_db.gearItems)
          ..where((g) => g.tripId.equals(tripId))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
    final meals = await _meals.watch(tripId).first;
    return [
      for (final g in gear) SetItem(kind: SetItem.gearKind, name: g.name, category: g.category, weight: g.weight, quantity: g.quantity),
      for (final m in meals..sort((a, b) {
        final d = a.dayIndex.compareTo(b.dayIndex);
        return d != 0 ? d : a.item.sortOrder.compareTo(b.item.sortOrder);
      }))
        SetItem(kind: SetItem.mealKind, name: m.item.name, category: m.item.mealType, weight: m.item.weight, calories: m.item.calories, quantity: m.item.quantity, day: m.dayIndex < 1 ? 1 : m.dayIndex, note: m.item.note),
    ];
  }

  Future<String> saveTripAs(String tripId, {required String title}) async => create(title: title, items: await itemsOfTrip(tripId));

  /// Adds [items] to the trip. Gear with the same name and category already in the trip is skipped; meals go to the
  /// matching trip day (created when missing).
  Future<ApplyResult> applyToTrip(String tripId, List<SetItem> items) async {
    final existing = await (_db.select(_db.gearItems)..where((g) => g.tripId.equals(tripId))).get();
    final have = {for (final g in existing) '${g.category}|${g.name.trim().toLowerCase()}'};
    var gearAdded = 0, gearSkipped = 0, mealsAdded = 0;
    for (final i in items.take(maxSetItems)) {
      if (i.isGear) {
        final key = '${i.category}|${i.name.trim().toLowerCase()}';
        if (!have.add(key)) {
          gearSkipped++;
          continue;
        }
        await _gear.add(tripId, name: i.name, weight: i.weight, category: i.category, quantity: i.quantity);
        gearAdded++;
      } else {
        await _meals.add(tripId, dayIndex: i.day, name: i.name, mealType: i.category, weight: i.weight, calories: i.calories, quantity: i.quantity, note: i.note);
        mealsAdded++;
      }
    }
    return ApplyResult(gearAdded: gearAdded, gearSkipped: gearSkipped, mealsAdded: mealsAdded);
  }
}
