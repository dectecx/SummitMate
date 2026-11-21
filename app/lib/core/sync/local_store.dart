import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'sync_entity.dart';

/// Generic row operations driven by [SyncEntity] descriptors.
///
/// SQL is built only from descriptor column names (a closed set); every value is a bound
/// variable. Writes go through Drift's `customUpdate` so that stream queries refresh.
class LocalStore {
  LocalStore(this._db);
  final AppDatabase _db;

  TableInfo<Table, dynamic> table(String name) =>
      _db.allTables.firstWhere((t) => t.actualTableName == name, orElse: () => throw ArgumentError('unknown table $name'));

  static Variable<Object> _v(Object? x) => switch (x) {
    null => const Variable<Object>(null),
    String s => Variable<Object>(s),
    int i => Variable<Object>(i),
    double d => Variable<Object>(d),
    _ => throw ArgumentError('unsupported variable type ${x.runtimeType}'),
  };

  Future<bool> exists(String tableName, String id) async {
    final rows = await _db.customSelect('SELECT 1 FROM $tableName WHERE id = ?', variables: [_v(id)]).get();
    return rows.isNotEmpty;
  }

  /// Local `trip_id` of a stored row, or null when the row (or column) does not exist.
  Future<String?> tripIdOf(String tableName, String id) async {
    if (tableName == 'trips') return await exists('trips', id) ? id : null;
    final rows = await _db.customSelect('SELECT trip_id FROM $tableName WHERE id = ?', variables: [_v(id)]).get();
    return rows.isEmpty ? null : rows.first.read<String>('trip_id');
  }

  /// Inserts or replaces the synced columns of [json] (a server row) for entity [e].
  /// Columns missing from [json] keep their existing or default value.
  Future<void> upsertFromServer(SyncEntity e, Map<String, Object?> json) async {
    final id = json['id'] as String;
    final cols = <String>[];
    final vals = <Object?>[];
    for (final entry in e.columns.entries) {
      if (!json.containsKey(entry.key)) continue;
      cols.add(entry.key);
      vals.add(toSql(entry.value, json[entry.key]));
    }
    final names = ['id', ...cols];
    final marks = List.filled(names.length, '?').join(', ');
    final sets = cols.isEmpty ? 'id = excluded.id' : cols.map((c) => '$c = excluded.$c').join(', ');
    await _db.customUpdate(
      'INSERT INTO ${e.name} (${names.join(', ')}) VALUES ($marks) ON CONFLICT(id) DO UPDATE SET $sets',
      variables: [_v(id), ...vals.map(_v)],
      updates: {table(e.name)},
      updateKind: UpdateKind.insert,
    );
  }

  /// Applies an outbox [patch] (changed fields only) onto an existing row.
  Future<void> applyPatch(SyncEntity e, String id, Map<String, Object?> patch) async {
    final cols = <String>[];
    final vals = <Object?>[];
    for (final entry in patch.entries) {
      final col = e.columns[entry.key];
      if (col == null) continue; // unknown keys are ignored defensively
      cols.add(entry.key);
      vals.add(toSql(col, entry.value));
    }
    if (cols.isEmpty) return;
    await _db.customUpdate(
      'UPDATE ${e.name} SET ${cols.map((c) => '$c = ?').join(', ')} WHERE id = ?',
      variables: [...vals.map(_v), _v(id)],
      updates: {table(e.name)},
      updateKind: UpdateKind.update,
    );
  }

  /// Deletes a row. Cascaded child rows are removed by SQLite, which Drift cannot see,
  /// so stream queries on the child tables are notified explicitly.
  Future<void> deleteRow(String tableName, String id) async {
    await _db.customUpdate(
      'DELETE FROM $tableName WHERE id = ?',
      variables: [_v(id)],
      updates: {table(tableName)},
      updateKind: UpdateKind.delete,
    );
    final cascaded = switch (tableName) {
      'trips' => syncEntities.where((e) => e.name != 'trips'),
      'meal_plan_days' => [mealItemsEntity],
      _ => const <SyncEntity>[],
    };
    if (cascaded.isNotEmpty) {
      _db.notifyUpdates({for (final e in cascaded) TableUpdate.onTable(table(e.name), kind: UpdateKind.delete)});
    }
  }

  /// Ids of rows that reference [parentId] through [column].
  Future<List<String>> childIds(String childTable, String column, String parentId) async {
    final rows = await _db.customSelect('SELECT id FROM $childTable WHERE $column = ?', variables: [_v(parentId)]).get();
    return [for (final r in rows) r.read<String>('id')];
  }

  Future<bool> isSampleTrip(String tripId) async {
    final rows = await _db.customSelect('SELECT is_sample FROM trips WHERE id = ?', variables: [_v(tripId)]).get();
    return rows.isNotEmpty && rows.first.read<int>('is_sample') == 1;
  }
}
