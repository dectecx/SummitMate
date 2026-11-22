// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';

/// The person's own reusable gear and foods. Writes go to the local table and the outbox together.
class LibraryRepository {
  LibraryRepository(this._db, this._outbox, {Uuid uuid = const Uuid()}) : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final Uuid _uuid;

  Stream<List<LibraryItem>> watch(String kind) =>
      (_db.select(_db.libraryItems)
            ..where((l) => l.kind.equals(kind))
            ..orderBy([(l) => OrderingTerm.asc(l.name)]))
          .watch();

  Future<String> add({required String kind, required String name, String category = 'other', double weight = 0, double calories = 0, String note = ''}) async {
    final id = _uuid.v7();
    await _db.transaction(() async {
      await _db.into(_db.libraryItems).insert(
        LibraryItemsCompanion.insert(id: id, kind: kind, name: Value(name), category: Value(category), weight: Value(weight), calories: Value(calories), note: Value(note)),
      );
      await _outbox.upsert(
        'library_items',
        id,
        {'kind': kind, 'name': name, 'category': category, 'weight': weight, 'calories': calories, 'note': note},
        isCreate: true,
      );
    });
    return id;
  }

  Future<void> update(String id, {String? name, String? category, double? weight, double? calories, String? note}) async {
    final patch = <String, Object?>{'name': ?name, 'category': ?category, 'weight': ?weight, 'calories': ?calories, 'note': ?note};
    if (patch.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.libraryItems)..where((l) => l.id.equals(id))).write(
        LibraryItemsCompanion(
          name: Value.absentIfNull(name),
          category: Value.absentIfNull(category),
          weight: Value.absentIfNull(weight),
          calories: Value.absentIfNull(calories),
          note: Value.absentIfNull(note),
        ),
      );
      await _outbox.upsert('library_items', id, patch);
    });
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('library_items', id);
    await (_db.delete(_db.libraryItems)..where((l) => l.id.equals(id))).go();
  });

  /// Adds the item to the library unless an item of the same kind and name (ignoring case) is already there.
  /// An existing entry is left as the person set it. Returns true when something was added.
  Future<bool> remember({required String kind, required String name, String category = 'other', double weight = 0, double calories = 0}) async {
    final clean = name.trim();
    if (clean.isEmpty) return false;
    final existing = await (_db.select(_db.libraryItems)..where((l) => l.kind.equals(kind) & l.name.lower().equals(clean.toLowerCase()))).get();
    if (existing.isNotEmpty) return false;
    await add(kind: kind, name: clean, category: category, weight: weight, calories: calories);
    return true;
  }
}
