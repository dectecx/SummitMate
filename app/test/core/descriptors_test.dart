import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('every descriptor matches its Drift table exactly', () {
    final store = LocalStore(db);
    for (final e in syncEntities) {
      final actual = store.table(e.name).$columns.map((c) => c.name).toSet();
      final expected = {'id', ...e.columns.keys, ...e.localOnlyColumns};
      expect(actual, expected, reason: 'columns of ${e.name} differ from its descriptor');
    }
  });

  test('every Drift sync table has a descriptor', () {
    final synced = {'trips', 'trip_members', 'itinerary_items', 'gear_items', 'meal_plan_days', 'meal_items', 'library_items', 'templates', 'trip_messages', 'polls', 'poll_options', 'poll_votes', 'favorites'};
    expect(syncEntities.map((e) => e.name).toSet(), synced);
    final infra = {'outbox', 'app_meta', 'app_settings', 'weather_cache', 'http_cache'};
    expect(db.allTables.map((t) => t.actualTableName).toSet(), {...synced, ...infra});
  });

  test('parents are declared before their children', () {
    final order = syncEntities.map((e) => e.name).toList();
    for (final e in syncEntities) {
      for (final p in e.parents) {
        expect(order.indexOf(p.table), lessThan(order.indexOf(e.name)), reason: '${e.name} needs ${p.table} first');
        expect(e.columns.containsKey(p.column), isTrue);
      }
    }
  });

  test('value conversion accepts server shapes and rejects wrong ones', () {
    expect(toSql(const Col(ColType.date), '2026-05-01T00:00:00Z'), '2026-05-01');
    expect(toSql(const Col(ColType.boolean), true), 1);
    expect(toSql(const Col(ColType.integer), 3.0), 3);
    expect(toSql(const Col(ColType.real), 2), 2.0);
    expect(toSql(const Col(ColType.timestamp, nullable: true), null), isNull);
    expect(() => toSql(const Col(ColType.text), null), throwsFormatException);
    expect(() => toSql(const Col(ColType.integer), 1.5), throwsFormatException);
    expect(() => toSql(const Col(ColType.timestamp), 'tomorrow'), throwsFormatException);
    expect(toJson(DateTime.utc(2026, 1, 2, 3)), '2026-01-02T03:00:00.000Z');
  });
}
