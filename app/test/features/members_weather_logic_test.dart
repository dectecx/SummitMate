import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/members/domain/member_logic.dart';
import 'package:summitmate/features/trips/domain/trip_logic.dart';
import 'package:summitmate/features/weather/domain/weather_models.dart';

Trip trip({String? owner}) => Trip(id: 't', ownerId: owner, name: 'x', description: '', startDate: '2026-05-01', endDate: null, coverImage: null, isSample: false);
TripMember member(String user, String role, {String name = ''}) => TripMember(id: 'm$user', tripId: 't', userId: user, role: role, displayName: name.isEmpty ? user : name, avatar: '🐻');

ItineraryItem node(String id, {int day = 1, int? minutes, double? lat, double? lng, int altitude = 0}) =>
    ItineraryItem(id: id, tripId: 't', dayIndex: day, name: id, estMinutes: minutes, altitude: altitude, distance: 0, lat: lat, lng: lng, note: '', checkedInAt: null);

void main() {
  group('member ids', () {
    test('match the server derivation (vectors asserted in the Go tests too)', () {
      expect(memberIdFor('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222'), 'cf807dd9-3045-5104-9b40-c032df6cf9b0');
      expect(memberIdFor('0192f3a0-0000-7000-8000-000000000001', '0192f3a0-0000-7000-8000-000000000002'), 'cb60a657-6b35-547f-a3a0-4181d7daa7c0');
    });

    test('are stable and distinct per pair', () {
      expect(memberIdFor('t', 'u'), memberIdFor('t', 'u'));
      expect(memberIdFor('t', 'u'), isNot(memberIdFor('t', 'v')));
      expect(memberIdFor('t', 'u'), isNot(memberIdFor('s', 'u')));
    });
  });

  group('members list', () {
    test('owner first, then guides, then members, each by name', () {
      final lines = buildMemberLines(
        trip: trip(owner: 'o'),
        members: [member('m2', 'member', name: 'Zed'), member('g', 'guide', name: 'Gus'), member('o', 'owner', name: 'Olly'), member('m1', 'member', name: 'Amy')],
        myId: 'm1',
        myName: 'Amy',
        myAvatar: '🐻',
      );
      expect(lines.map((l) => l.displayName), ['Olly', 'Gus', 'Amy', 'Zed']);
      expect(lines.firstWhere((l) => l.isMe).displayName, 'Amy');
    });

    test('the signed-in person appears even before the server delivers their own row', () {
      final lines = buildMemberLines(trip: trip(owner: 'me'), members: const [], myId: 'me', myName: 'Me', myAvatar: '');
      expect(lines, hasLength(1));
      expect([lines.single.role, lines.single.isMe, lines.single.avatar], [TripRole.owner, true, '🙂']);
    });

    test('a guest sees nobody', () {
      expect(buildMemberLines(trip: trip(), members: const [], myId: null, myName: '', myAvatar: ''), isEmpty);
    });

    test('who may manage whom', () {
      bool can(TripRole me, TripRole target) => canManageMember(me: me, target: target);
      expect([can(TripRole.owner, TripRole.guide), can(TripRole.owner, TripRole.member), can(TripRole.owner, TripRole.owner)], [true, true, false]);
      expect([can(TripRole.guide, TripRole.member), can(TripRole.guide, TripRole.guide), can(TripRole.guide, TripRole.owner)], [true, false, false]);
      expect([can(TripRole.member, TripRole.member), can(TripRole.member, TripRole.guide)], [false, false]);
      expect([canInvite(TripRole.owner), canInvite(TripRole.guide), canInvite(TripRole.member)], [true, true, false]);
    });
  });

  group('weather models', () {
    final payload = jsonEncode({
      'latitude': 23.44, 'longitude': 121.04, 'elevation': 3000, 'timezone': 'Asia/Taipei', 'fetched_at': '2026-11-22T01:00:00Z',
      'daily': [
        {'date': '2026-11-22', 'weather_code': 1, 'temp_max': 11.1, 'temp_min': 2, 'precipitation_probability_max': 2, 'precipitation_sum': 0, 'wind_speed_max': 11.7, 'wind_gusts_max': 41.8},
        {'date': '2026-11-23', 'weather_code': 53, 'temp_max': 13.7, 'temp_min': 2.4, 'precipitation_probability_max': null, 'precipitation_sum': 1.3, 'wind_speed_max': 13, 'wind_gusts_max': null},
      ],
    });

    test('parse the server response, including nulls', () {
      final f = WeatherForecast.parse(payload);
      expect([f.latitude, f.elevation, f.daily.length], [23.44, 3000.0, 2]);
      expect(f.fetchedAt, DateTime.utc(2026, 11, 22, 1));
      expect(f.daily[0].date, DateTime(2026, 11, 22));
      expect([f.daily[0].tempMax, f.daily[0].tempMin, f.daily[0].rainChance, f.daily[0].gustMax], [11.1, 2.0, 2, 41.8]);
      expect([f.daily[1].rainChance, f.daily[1].gustMax, f.daily[1].rainMm], [null, null, 1.3]);
    });

    test('garbage is rejected instead of half-parsed', () {
      expect(() => WeatherForecast.parse('not json'), throwsFormatException);
      expect(() => WeatherForecast.parse('{"latitude": 1}'), throwsA(anything));
    });

    test('nearby points share a cache key the same way the server rounds them', () {
      expect(weatherCacheKey((lat: 23.4012, lng: 121.0049, elevation: 2960)), weatherCacheKey((lat: 23.4049, lng: 121.0001, elevation: 3040)));
      expect(weatherCacheKey((lat: 23.4, lng: 121.0, elevation: null)), '23.40,121.00,-');
      expect(weatherCacheKey((lat: 23.4, lng: 121.0, elevation: 3000)), isNot(weatherCacheKey((lat: 23.4, lng: 121.0, elevation: 2700))));
    });

    test('each day is forecast at its highest located node, then the previous day, then the main mountain', () {
      final items = [
        node('no-coords', minutes: 60),
        node('low', day: 1, minutes: 420, lat: 23.5, lng: 121.1, altitude: 2300),
        node('summit', day: 1, minutes: 600, lat: 23.4, lng: 121.0, altitude: 2700),
        node('flat', day: 3, lat: 1, lng: 2),
      ];
      final plan = weatherPlanFor(start: DateTime(2026, 5, 10), dayCount: 4, items: items, fallback: (lat: 9.0, lng: 9.0, elevation: 3952), fallbackName: '玉山');
      expect(plan.map((p) => p.query), [
        (lat: 23.4, lng: 121.0, elevation: 2700),
        (lat: 23.4, lng: 121.0, elevation: 2700), // day 2 has no located node: stays at day 1's place
        (lat: 1.0, lng: 2.0, elevation: null), // no altitude means no elevation correction
        (lat: 1.0, lng: 2.0, elevation: null),
      ]);
      expect(plan.first.placeName, 'summit');
      expect(plan[1].date, DateTime(2026, 5, 11));
      final onlyMountain = weatherPlanFor(start: DateTime(2026, 5, 10), dayCount: 2, items: [node('x')], fallback: (lat: 9.0, lng: 9.0, elevation: 3952), fallbackName: '玉山');
      expect(onlyMountain.map((p) => p.placeName), ['玉山', '玉山']);
      expect(weatherPlanFor(start: DateTime(2026, 5, 10), dayCount: 1, items: [node('x')]).single.query, isNull);
    });

    test('advice only appears when the weather calls for it', () {
      DailyForecast d({int code = 0, double min = 10, int? rain = 10, double mm = 0, double wind = 10, double? gust}) =>
          DailyForecast(date: DateTime(2026, 5, 10), weatherCode: code, tempMax: 20, tempMin: min, rainChance: rain, rainMm: mm, windMax: wind, gustMax: gust);
      expect(weatherAdvice(d()), isNull);
      expect(weatherAdvice(d(rain: 70)), contains('雨具'));
      expect(weatherAdvice(d(min: 0, wind: 50)), allOf(contains('保暖'), contains('強風')));
      expect(weatherAdvice(d(code: 95)), contains('雷雨'));
    });
  });
}
