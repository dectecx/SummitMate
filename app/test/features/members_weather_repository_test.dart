import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/members/data/member_repository.dart';
import 'package:summitmate/features/members/domain/member_logic.dart';
import 'package:summitmate/features/trips/data/itinerary_repository.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';
import 'package:summitmate/features/weather/data/weather_repository.dart';
import 'package:summitmate/features/weather/domain/weather_models.dart';

import '../core/support.dart';

class FakeWeatherApi implements WeatherApi {
  int calls = 0;
  Object? failWith;
  String payload = jsonEncode({
    'latitude': 23.4, 'longitude': 121.0, 'elevation': 3000, 'timezone': 'Asia/Taipei', 'fetched_at': '2026-11-22T01:00:00Z',
    'daily': [{'date': '2026-11-22', 'weather_code': 1, 'temp_max': 11, 'temp_min': 2, 'precipitation_probability_max': 5, 'precipitation_sum': 0, 'wind_speed_max': 10, 'wind_gusts_max': 30}],
  });

  @override
  Future<String> forecast(WeatherQuery q, {int days = 7}) async {
    calls++;
    final f = failWith;
    if (f != null) throw f;
    return payload;
  }
}

const _alice = FoundUser(id: 'alice-id', displayName: 'Alice', avatar: '🦊');

void main() {
  late AppDatabase db;
  late TripRepository trips;
  late MemberRepository members;
  late String trip;

  setUp(() async {
    db = memoryDb();
    final writer = OutboxWriter(db);
    trips = TripRepository(db, writer);
    members = MemberRepository(db, writer);
    trip = await trips.create(name: 't', start: DateTime(2026, 5, 1));
    await db.delete(db.outbox).go();
  });
  tearDown(() => db.close());

  group('members', () {
    test('inviting stores the person with the deterministic id and queues the creation', () async {
      await members.invite(trip, _alice, role: 'guide');

      final row = (await db.select(db.tripMembers).get()).single;
      expect([row.id, row.userId, row.role, row.displayName, row.avatar], [memberIdFor(trip, 'alice-id'), 'alice-id', 'guide', 'Alice', '🦊']);
      final op = (await db.select(db.outbox).get()).single;
      expect(op.entity, 'trip_members');
      expect(op.entityId, row.id);
      expect(op.isCreate, isTrue);
      expect(patchOf(op), {'trip_id': trip, 'user_id': 'alice-id', 'role': 'guide'});
    });

    test('changing a role is a small patch; removing someone who never reached the server sends nothing', () async {
      await members.invite(trip, _alice);
      await members.setRole(trip, 'alice-id', 'guide');
      expect((await db.select(db.tripMembers).get()).single.role, 'guide');
      expect(patchOf((await db.select(db.outbox).get()).single), containsPair('role', 'guide'));

      await members.remove(trip, 'alice-id');
      expect(await select(db, 'SELECT id FROM trip_members'), isEmpty);
      expect(await opSummary(db), isEmpty, reason: 'the invitation never left this device');
    });

    test('removing a member the server already knows queues one deletion', () async {
      await members.invite(trip, _alice);
      await db.delete(db.outbox).go(); // uploaded
      await members.remove(trip, 'alice-id');
      expect(await opSummary(db), ['delete:trip_members/${memberIdFor(trip, 'alice-id')}']);
    });

    test('re-inviting after a removal reuses the same row id', () async {
      await members.invite(trip, _alice);
      await members.remove(trip, 'alice-id');
      await members.invite(trip, _alice);
      expect((await db.select(db.tripMembers).get()).single.id, memberIdFor(trip, 'alice-id'));
    });

    test('leaving removes the trip here, drops its queued work, and only tells the server about the membership', () async {
      final items = ItineraryRepository(db, OutboxWriter(db));
      await items.add(trip, dayIndex: 1, name: 'queued edit');
      await trips.update(trip, name: 'renamed');
      expect(await opSummary(db), isNotEmpty);

      await members.leave(trip, 'me-id');

      expect(await select(db, 'SELECT id FROM trips'), isEmpty);
      expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
      expect(await opSummary(db), ['delete:trip_members/${memberIdFor(trip, 'me-id')}']);
    });
  });

  group('weather repository', () {
    const q = (lat: 23.4, lng: 121.0, elevation: 3000);
    late FakeWeatherApi api;
    late DateTime now;
    late WeatherRepository repo;

    setUp(() {
      api = FakeWeatherApi();
      now = DateTime(2026, 11, 22, 10);
      repo = WeatherRepository(db, api, now: () => now);
    });

    test('with nothing cached it loads, fetches and stores the forecast', () async {
      final states = await repo.watch(q, signedIn: true).toList();
      expect(states.map((s) => s.runtimeType), [WeatherLoading, WeatherData]);
      expect((states.last as WeatherData).stale, isFalse);
      expect(api.calls, 1);
      expect(await select(db, 'SELECT key FROM weather_cache'), [{'key': '23.40,121.00,3000'}]);
    });

    test('a fresh cache is shown without calling the server', () async {
      await repo.watch(q, signedIn: true).toList();
      now = now.add(const Duration(hours: 1));
      final states = await repo.watch(q, signedIn: true).toList();
      expect(states.map((s) => s.runtimeType), [WeatherData]);
      expect(api.calls, 1);
    });

    test('an old cache is shown at once as stale and then refreshed', () async {
      await repo.watch(q, signedIn: true).toList();
      now = now.add(const Duration(hours: 4));
      final states = await repo.watch(q, signedIn: true).toList();
      expect(states.map((s) => (s as WeatherData).stale), [true, false]);
      expect(api.calls, 2);
    });

    test('offline with an old cache keeps showing it and says the refresh failed', () async {
      await repo.watch(q, signedIn: true).toList();
      now = now.add(const Duration(hours: 4));
      api.failWith = Exception('offline');
      final last = (await repo.watch(q, signedIn: true).toList()).last as WeatherData;
      expect([last.stale, last.refreshFailed], [true, true]);
    });

    test('offline with nothing cached is unavailable', () async {
      api.failWith = Exception('offline');
      expect((await repo.watch(q, signedIn: true).toList()).last, isA<WeatherUnavailable>());
      expect(await select(db, 'SELECT key FROM weather_cache'), isEmpty);
    });

    test('a guest has no token: needs login, but still sees a cached forecast', () async {
      expect((await repo.watch(q, signedIn: false).toList()).single, isA<WeatherNeedsLogin>());
      expect(api.calls, 0);
      await repo.watch(q, signedIn: true).toList();
      now = now.add(const Duration(hours: 5));
      final states = await repo.watch(q, signedIn: false).toList();
      expect(states.single, isA<WeatherData>());
      expect((states.single as WeatherData).stale, isTrue);
    });

    test('an unreadable server answer is never stored', () async {
      api.payload = '{"oops": true}';
      expect((await repo.watch(q, signedIn: true).toList()).last, isA<WeatherUnavailable>());
      expect(await select(db, 'SELECT key FROM weather_cache'), isEmpty);
    });

    test('a cache row from an unreadable older version is replaced', () async {
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(key: '23.40,121.00,3000', payload: 'junk', fetchedAt: now));
      final states = await repo.watch(q, signedIn: true).toList();
      expect(states.last, isA<WeatherData>());
      expect(api.calls, 1);
    });
  });

  test('nodes can carry coordinates, which are cleared together', () async {
    final items = ItineraryRepository(db, OutboxWriter(db));
    final id = await items.add(trip, dayIndex: 1, name: 'peak', lat: 23.4, lng: 121.0);
    var row = (await db.select(db.itineraryItems).get()).single;
    expect([row.lat, row.lng], [23.4, 121.0]);
    expect(patchOf((await db.select(db.outbox).get()).single), containsPair('lat', 23.4));

    await items.update(id, lat: const Value(null), lng: const Value(null));
    row = (await db.select(db.itineraryItems).get()).single;
    expect([row.lat, row.lng], [null, null]);
  });
}
