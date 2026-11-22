import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/explore/domain/mountain_models.dart';
import 'package:summitmate/features/gpx/domain/gpx_codec.dart';
import 'package:summitmate/features/gpx/domain/gpx_models.dart';
import 'package:summitmate/features/trips/data/gpx_import.dart';
import 'package:summitmate/features/trips/data/itinerary_repository.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';
import 'package:summitmate/features/trips/domain/gpx_trip.dart';
import 'package:summitmate/features/trips/ui/gpx_actions.dart';

import '../core/support.dart';
import 'explore_test.dart' show m;

// Two days: D1 07:00 trailhead (2300 m) -> hut (2850 m) 11:00; D2 06:00 summit (3100 m) -> 10:00 trailhead. UTC+0 times, Taiwan is +8.
GpxDocument sample({bool waypoints = true}) {
  GpxPoint p(double lat, double ele, String t) => GpxPoint(lat: lat, lng: 121.0, ele: ele, time: DateTime.parse(t));
  return GpxDocument(
    name: '向陽山屋',
    waypoints: waypoints
        ? const [
            GpxWaypoint(name: '登山口', lat: 23.30, lng: 121.0, ele: 2300),
            GpxWaypoint(name: '山屋', lat: 23.31, lng: 121.0),
            GpxWaypoint(name: '山頭', lat: 23.32, lng: 121.0, ele: 3100),
          ]
        : const [],
    tracks: [
      GpxTrack(name: 't', points: [
        p(23.30, 2300, '2026-05-09T23:00:00Z'), // 07:00 on 5/10 Taiwan time
        p(23.31, 2850, '2026-05-10T03:00:00Z'),
        p(23.32, 3100, '2026-05-10T22:00:00Z'), // 06:00 on 5/11
        p(23.30, 2300, '2026-05-11T02:00:00Z'),
      ]),
    ],
  );
}

void main() {
  test('waypoints become nodes in track order, with days, times, altitudes and distances from the track', () {
    final t = tripFromGpx(sample(), today: DateTime(2026, 1, 1));
    expect(t.name, '向陽山屋');
    expect(t.start, DateTime(2026, 5, 10));
    expect(t.dayCount, 2);
    expect(t.nodes.map((n) => n.name), ['登山口', '山屋', '山頭']);
    expect(t.nodes.map((n) => n.dayIndex), [1, 1, 2]);
    expect(t.nodes.map((n) => n.estMinutes), [7 * 60, 11 * 60, 6 * 60]);
    expect(t.nodes.map((n) => n.altitude), [2300, 2850, 3100], reason: 'a waypoint without elevation takes it from the nearest track point');
    expect(t.nodes[0].distanceKm, 0);
    expect(t.nodes[1].distanceKm, closeTo(1.11, 0.02));
    expect(t.track.length, 4);
  });

  test('without waypoints the start, highest point and end are proposed', () {
    final t = tripFromGpx(sample(waypoints: false), today: DateTime(2026, 1, 1));
    expect(t.nodes.map((n) => n.name), ['起點', '最高點', '終點']);
    expect(t.nodes[1].altitude, 3100);
  });

  test('a file without timestamps is one day starting today, and an unnamed file gets a default name', () {
    const doc = GpxDocument(tracks: [GpxTrack(name: '', points: [GpxPoint(lat: 23.3, lng: 121.0, ele: 100), GpxPoint(lat: 23.31, lng: 121.0, ele: 200)])]);
    final t = tripFromGpx(doc, today: DateTime(2026, 6, 1, 15));
    expect([t.name, t.dayCount, t.start], ['匯入的行程', 1, DateTime(2026, 6, 1)]);
    expect(t.nodes.every((n) => n.estMinutes == null), isTrue);
  });

  test('a stored track is simplified to at most 500 points and survives encoding; damaged text gives an empty track', () {
    final many = [for (var i = 0; i < 5000; i++) GpxPoint(lat: 23 + i / 100000, lng: 121, ele: 1000 + i / 10)];
    final simple = simplifyTrack(many);
    expect(simple.length, 500);
    expect([simple.first.lat, simple.last.lat], [many.first.lat, many.last.lat]);
    final json = encodeTrack(simple);
    expect(json.length, lessThan(20000), reason: 'small enough to sync inside the trip row');
    final back = decodeTrack(json);
    expect(back.length, 500);
    expect(back.first.ele, 1000);
    expect(decodeTrack('not json'), isEmpty);
    expect(decodeTrack(null), isEmpty);
  });

  group('with a database', () {
    late AppDatabase db;
    late TripRepository trips;
    late ItineraryRepository items;
    setUp(() {
      db = memoryDb();
      final w = OutboxWriter(db);
      trips = TripRepository(db, w);
      items = ItineraryRepository(db, w);
    });
    tearDown(() => db.close());

    test('importing creates the trip with its dates, track and nodes, all queued for upload', () async {
      final id = await importGpxTrip(trips, items, tripFromGpx(sample(), today: DateTime(2026, 1, 1)), mountainId: 'x');
      final trip = await (db.select(db.trips)..where((t) => t.id.equals(id))).getSingle();
      expect([trip.name, trip.startDate, trip.endDate, trip.mountainId], ['向陽山屋', '2026-05-10', '2026-05-11', 'x']);
      expect(decodeTrack(trip.track).length, 4);
      expect((await db.select(db.itineraryItems).get()).length, 3);
      final ops = await db.select(db.outbox).get();
      expect(ops.length, 4, reason: 'one trip and three nodes');
    });

    test('exporting writes waypoints and the track, and it reads back', () async {
      final id = await importGpxTrip(trips, items, tripFromGpx(sample(), today: DateTime(2026, 1, 1)));
      final trip = await (db.select(db.trips)..where((t) => t.id.equals(id))).getSingle();
      final doc = parseGpx(gpxForTrip(trip, await db.select(db.itineraryItems).get()));
      expect(doc.name, '向陽山屋');
      expect(doc.waypoints.map((w) => w.name), ['登山口', '山屋', '山頭']);
      expect(doc.tracks.single.points.length, 4);
    });
  });

  test('the nearest listed mountain within range is chosen', () {
    final list = [Mountain.fromJson(m('a', '甲山', 3000)), Mountain.fromJson({...m('b', '乙山', 3100), 'latitude': 24.5})];
    expect(nearestMountainId(list, list[0].latitude, list[0].longitude, maxKm: 3), 'a');
    expect(nearestMountainId(list, 0, 0, maxKm: 3), isNull);
  });
}
