import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/explore/data/mountain_repository.dart';
import 'package:summitmate/features/explore/domain/mountain_models.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/trips/providers.dart';
import 'package:summitmate/features/weather/data/weather_repository.dart';
import 'package:summitmate/features/weather/domain/weather_models.dart';
import 'package:summitmate/features/weather/providers.dart';

import '../core/support.dart';
import 'harness.dart';

Map<String, Object?> m(String id, String name, int elev, {String region = '玉山國家公園', bool beginner = false, String category = 'baiyue', int? grade, String? permit, String? nameEn}) => {
  'id': id, 'name': name, 'name_en': nameEn, 'elevation': elev, 'region': region, 'latitude': 23.47, 'longitude': 120.96, 'category': category,
  'trail_grade': grade, 'beginner_friendly': beginner, 'summary': '$name 的簡介', 'permit': permit, 'verified': false, 'sources': ['https://example.org/$id'],
};

String payloadOf(List<Map<String, Object?>> ms, {String version = 'v1'}) => jsonEncode({'version': version, 'updated_at': '2026-11-22T00:00:00Z', 'mountains': ms});

final _sample = [
  m('yushan-main', '玉山主峰', 3952, nameEn: 'Yushan Main Peak', permit: '需申請入園與入山'),
  m('xueshan-main', '雪山主峰', 3886, region: '雪霸國家公園', grade: 3),
  m('hehuanshan-main', '合歡山主峰', 3417, region: '太魯閣國家公園', beginner: true, grade: 1),
  m('little-one', '某座小山', 1500, category: 'other', beginner: true),
];

class FakeExploreApi implements ExploreApi {
  FakeExploreApi(this.payload, {this.etag = '"v1"'});
  String payload;
  String? etag;
  Object? failWith;
  final List<String?> etagsSeen = [];

  @override
  Future<MountainsResponse> fetchMountains({String? etag}) async {
    etagsSeen.add(etag);
    final f = failWith;
    if (f != null) throw f;
    if (etag != null && etag == this.etag) return const MountainsResponse.notModified();
    return MountainsResponse.fresh(payload, this.etag);
  }
}

class FakeWeatherApi implements WeatherApi {
  @override
  Future<String> forecast(WeatherQuery q, {int days = 7}) async => jsonEncode({
    'latitude': q.lat, 'longitude': q.lng, 'elevation': q.elevation, 'timezone': 'Asia/Taipei', 'fetched_at': '2026-11-22T01:00:00Z',
    'daily': [{'date': '2026-11-22', 'weather_code': 0, 'temp_max': 9.0, 'temp_min': 1.0, 'precipitation_probability_max': 10, 'precipitation_sum': 0, 'wind_speed_max': 8, 'wind_gusts_max': null}],
  });
}

void main() {
  group('models and search', () {
    final list = MountainList.parse(payloadOf(_sample));

    test('parse the server list', () {
      expect(list.version, 'v1');
      expect(list.mountains.length, 4);
      final y = list.byId('yushan-main')!;
      expect([y.name, y.nameEn, y.elevation, y.category, y.permit, y.verified], ['玉山主峰', 'Yushan Main Peak', 3952, MountainCategory.baiyue, '需申請入園與入山', false]);
      expect(list.byId('hehuanshan-main')!.trailGrade, 1);
      expect(list.byId('little-one')!.trailGrade, isNull);
      expect(list.byId('little-one')!.category, MountainCategory.other);
      expect(list.byId('missing'), isNull);
    });

    test('garbage is rejected', () {
      expect(() => MountainList.parse('nope'), throwsFormatException);
      expect(() => MountainList.parse('{"version":"x"}'), throwsA(anything));
    });

    test('results are highest first and can be filtered and searched', () {
      expect(searchMountains(list.mountains).map((e) => e.id), ['yushan-main', 'xueshan-main', 'hehuanshan-main', 'little-one']);
      expect(searchMountains(list.mountains, filter: MountainFilter.beginner).map((e) => e.id), ['hehuanshan-main', 'little-one']);
      expect(searchMountains(list.mountains, filter: MountainFilter.baiyue).length, 3);
      expect(searchMountains(list.mountains, query: '雪霸').map((e) => e.id), ['xueshan-main'], reason: 'matches the region');
      expect(searchMountains(list.mountains, query: ' yushan ').map((e) => e.id), ['yushan-main'], reason: 'English name, trimmed, any case');
      expect(searchMountains(list.mountains, query: '山', filter: MountainFilter.beginner).map((e) => e.id), ['hehuanshan-main', 'little-one']);
      expect(searchMountains(list.mountains, query: 'zzz'), isEmpty);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late FakeExploreApi api;
    late DateTime now;
    late MountainRepository repo;

    setUp(() {
      db = memoryDb();
      api = FakeExploreApi(payloadOf(_sample));
      now = DateTime(2026, 11, 22, 10);
      repo = MountainRepository(db, api, now: () => now);
    });
    tearDown(() => db.close());

    test('first load fetches and stores the list with its etag', () async {
      final states = await repo.watch().toList();
      expect(states.map((s) => s.runtimeType), [MountainsLoading, MountainsReady]);
      expect(api.etagsSeen, [null]);
      final row = (await db.select(db.httpCache).get()).single;
      expect([row.key, row.etag], ['mountains', '"v1"']);
    });

    test('a fresh cache is shown without calling the server', () async {
      await repo.watch().toList();
      now = now.add(const Duration(days: 2));
      expect((await repo.watch().toList()).map((s) => s.runtimeType), [MountainsReady]);
      expect(api.etagsSeen.length, 1);
    });

    test('an old cache is shown at once, then checked with If-None-Match and kept on 304', () async {
      await repo.watch().toList();
      now = now.add(const Duration(days: 8));
      final states = await repo.watch().toList();
      expect(states.map((s) => s.runtimeType), [MountainsReady, MountainsReady]);
      expect(api.etagsSeen, [null, '"v1"']);
      expect((await db.select(db.httpCache).get()).single.fetchedAt, now, reason: 'the clock restarts');
    });

    test('a changed list replaces the cache', () async {
      await repo.watch().toList();
      api
        ..payload = payloadOf([m('only-one', '唯一的山', 2000)], version: 'v2')
        ..etag = '"v2"';
      now = now.add(const Duration(days: 8));
      final last = (await repo.watch().toList()).last as MountainsReady;
      expect([last.data.version, last.data.mountains.length], ['v2', 1]);
      expect((await db.select(db.httpCache).get()).single.etag, '"v2"');
    });

    test('offline: old cache stays visible and says the refresh failed; no cache means unavailable', () async {
      api.failWith = Exception('offline');
      expect((await repo.watch().toList()).last, isA<MountainsUnavailable>());

      api.failWith = null;
      await repo.watch().toList();
      api.failWith = Exception('offline');
      now = now.add(const Duration(days: 8));
      final last = (await repo.watch().toList()).last as MountainsReady;
      expect(last.refreshFailed, isTrue);
    });

    test('an unreadable server answer is never stored', () async {
      api.payload = '{"broken": true}';
      expect((await repo.watch().toList()).last, isA<MountainsUnavailable>());
      expect(await select(db, 'SELECT key FROM http_cache'), isEmpty);
    });
  });

  group('screens', () {
    Future<AppHarness> start(WidgetTester tester, FakeExploreApi api) => AppHarness.start(
      tester,
      welcomeSeen: true,
      overrides: [
        exploreApiProvider.overrideWithValue(api),
        weatherApiProvider.overrideWithValue(FakeWeatherApi()),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
      ],
    );

    testWidgets('list, search and filters', (tester) async {
      final app = await start(tester, FakeExploreApi(payloadOf(_sample)));
      await tapText(tester, '探索');
      expect(find.text('玉山主峰'), findsOneWidget);
      expect(find.text('玉山國家公園  ·  3952 m'), findsOneWidget);
      expect(find.text('某座小山'), findsOneWidget);

      await tapText(tester, '新手推薦');
      expect(find.text('玉山主峰'), findsNothing);
      expect(find.text('合歡山主峰'), findsOneWidget);
      expect(find.text('1 級'), findsOneWidget);

      await tapText(tester, '全部');
      await tester.enterText(find.byType(TextField), '雪霸');
      await settle(tester);
      expect(find.text('雪山主峰'), findsOneWidget);
      expect(find.text('玉山主峰'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await settle(tester);
      expect(find.text('沒有符合的山'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('a mountain page shows the facts, the unverified notice, and the weather for its summit', (tester) async {
      tester.view.physicalSize = const Size(800, 2400); // tall: the banner pushes the sources down
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await start(tester, FakeExploreApi(payloadOf(_sample)));
      await tapText(tester, '探索');
      await tapText(tester, '玉山主峰');

      expect(find.textContaining('Yushan Main Peak'), findsOneWidget);
      expect(find.text('3952 m'), findsOneWidget);
      expect(find.text('台灣百岳'), findsOneWidget);
      expect(find.text('玉山主峰 的簡介'), findsOneWidget);
      expect(find.text('需申請入園與入山'), findsOneWidget);
      expect(find.textContaining('尚未經人工核實'), findsOneWidget);
      expect(find.text('登入後可以查看天氣預報。'), findsOneWidget, reason: 'a guest has no token for the weather endpoint');
      expect(find.textContaining('example.org', findRichText: true), findsOneWidget, reason: 'sources show the site name and open the address when tapped');
      await app.dispose(tester);
    });

    testWidgets('first launch without a connection explains why the list is empty', (tester) async {
      final api = FakeExploreApi(payloadOf(_sample))..failWith = Exception('offline');
      final app = await start(tester, api);
      await tapText(tester, '探索');
      expect(find.textContaining('第一次使用需要連上網路'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
