import 'package:drift/drift.dart';

// Local mirror of the server's syncable tables (see docs/architecture/FRONTEND_DATA.md).
// Column names (snake_case) are identical to the server JSON so outbox patches can be
// sent as-is. There is deliberately no per-row sync status: pending work lives in [Outbox].
//
// Personal data (gear, meal plan days, meal items) has no user_id: the server only
// returns the signed-in user's rows, so every local row is "mine".

class Trips extends Table {
  TextColumn get id => text()();
  // Null for trips created as a guest until the server confirms the owner.
  TextColumn get ownerId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  // YYYY-MM-DD. Date-only, never converted through a time zone.
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  // Main mountain (an id from the explore list); weather and map hints follow it.
  TextColumn get mountainId => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  // Local only: the bundled example trip. Never enters the outbox.
  BoolColumn get isSample => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class TripMembers extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class ItineraryItems extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayIndex => integer().withDefault(const Constant(0))();
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get estMinutes => integer().nullable()();
  IntColumn get altitude => integer().withDefault(const Constant(0))();
  RealColumn get distance => real().withDefault(const Constant(0))();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get checkedInAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GearItems extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withDefault(const Constant(''))();
  RealColumn get weight => real().withDefault(const Constant(0))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class MealPlanDays extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get dayIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class MealItems extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get mealPlanDayId => text().references(MealPlanDays, #id, onDelete: KeyAction.cascade)();
  TextColumn get mealType => text().withDefault(const Constant('other'))();
  TextColumn get name => text().withDefault(const Constant(''))();
  RealColumn get weight => real().withDefault(const Constant(0))();
  RealColumn get calories => real().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending client operations, sent to the server in `seq` order.
@DataClassName('OutboxOp')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  // Idempotency key. Regenerated when an already-sent op is edited, because the
  // server would otherwise replay its cached result for the old content.
  TextColumn get opId => text().unique()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  // 'upsert' | 'delete'
  TextColumn get type => text()();
  // JSON object of changed fields (all fields + trip_id for a creation).
  TextColumn get patch => text().withDefault(const Constant('{}'))();
  // True while the server has not yet seen this entity (a creation).
  BoolColumn get isCreate => boolean().withDefault(const Constant(false))();
  // True once a request carrying this op has been sent; the server may have applied it.
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
  // 'pending' | 'failed'
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Single-row table (id = 1): which account owns this device's data and the sync cursor.
class AppMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  // Null while the device is in guest mode.
  TextColumn get accountId => text().nullable()();
  // The server's `next_since` string, stored verbatim (never parsed) to keep microseconds.
  TextColumn get syncCursor => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatar => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Last forecast received for a place, so the weather can still be read without a connection.
/// The key identifies the place (rounded coordinates and elevation); the payload is the server's JSON.
class WeatherCache extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Last response of a cacheable reference endpoint (e.g. the mountain list) with its ETag, so the
/// app can show it offline and ask the server "has it changed?" cheaply.
class HttpCache extends Table {
  TextColumn get key => text()();
  TextColumn get etag => text().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Offline map downloads: one row per region the person asked for. Absent = not downloaded.
/// The tiles themselves live in the tile cache (one cache store per region, named after [id]).
class OfflineRegions extends Table {
  TextColumn get id => text()();
  // 'queued' | 'downloading' | 'done' | 'failed' | 'interrupted'
  TextColumn get state => text()();
  IntColumn get tilesDone => integer().withDefault(const Constant(0))();
  IntColumn get tilesTotal => integer().withDefault(const Constant(0))();
  // Bytes of the tiles downloaded so far.
  RealColumn get bytes => real().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
