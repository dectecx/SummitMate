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
  // Simplified GPX track as compact JSON [[lat,lng,ele],...]; see features/trips/domain/track_codec.dart.
  TextColumn get track => text().nullable()();
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

/// A reusable item of the person's own library: a piece of gear or a food they use often.
class LibraryItems extends Table {
  TextColumn get id => text()();
  // 'gear' or 'meal'
  TextColumn get kind => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  // Gear: a GearCategory key. Meal: a MealType key.
  TextColumn get category => text().withDefault(const Constant('other'))();
  RealColumn get weight => real().withDefault(const Constant(0))();
  RealColumn get calories => real().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A saved packing list and meal plan the person can apply to any trip. `items` is a JSON array
/// (see features/library/domain/set_item.dart).
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get items => text().withDefault(const Constant('[]'))();

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

/// A message on a trip's board. `user_id` is the author as the server knows them; it is never
/// uploaded (the server forces it to the actor). Null = written here before the person signed
/// in; sign-in fills it in (see LocalAccountStore.onSignedIn).
class TripMessages extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().nullable()();
  // A reply points at a top-level message. Deliberately no foreign key: messages are pulled in
  // `updated_at` order, so a reply can arrive before its parent.
  TextColumn get parentId => text().nullable()();
  TextColumn get body => text()();
  // Server time (not uploaded); set from the device clock until the server's value arrives.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Polls extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get allowMultiple => boolean().withDefault(const Constant(false))();
  BoolColumn get allowAddOption => boolean().withDefault(const Constant(false))();
  // Results stay hidden until the poll is closed or past its deadline.
  BoolColumn get blind => boolean().withDefault(const Constant(false))();
  // 'open' | 'closed'
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PollOptions extends Table {
  TextColumn get id => text()();
  TextColumn get pollId => text().references(Polls, #id, onDelete: KeyAction.cascade)();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text().named('text')();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // Who added the option (server column, not uploaded): members may remove only their own.
  TextColumn get createdBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One person's vote for one option. A retraction deletes the row (and queues a tombstone);
/// voting again revives the same deterministic id. `user_id` follows the same rule as messages;
/// a guest's rows use the placeholder id 'local' until sign-in re-keys them.
class PollVotes extends Table {
  TextColumn get id => text()();
  TextColumn get pollId => text().references(Polls, #id, onDelete: KeyAction.cascade)();
  TextColumn get optionId => text().references(PollOptions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().nullable()();
  // Server time of the last change (not uploaded): the newest vote wins in a single-choice poll.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A starred item of the signed-in person (no trip). Rows are deduplicated by (kind, target_id)
/// when read, since two devices can create the same favorite.
class Favorites extends Table {
  TextColumn get id => text()();
  // 'mountain' | 'group_event'
  TextColumn get kind => text()();
  TextColumn get targetId => text()();

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
