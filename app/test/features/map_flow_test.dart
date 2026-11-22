import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/map/data/location_service.dart';
import 'package:summitmate/features/map/data/tile_cache.dart';
import 'package:summitmate/features/map/data/tile_downloader.dart';
import 'package:summitmate/features/explore/domain/mountain_models.dart';
import 'package:summitmate/features/map/domain/map_logic.dart';
import 'package:summitmate/features/map/domain/offline_regions.dart';
import 'package:summitmate/features/map/domain/offline_view.dart';
import 'package:summitmate/features/map/providers.dart';
import 'package:summitmate/core/db/app_database.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';
import 'offline_manager_test.dart' show FakeDownloader;

class FakeTileCache implements TileCache {
  FakeTileCache(this.downloader);
  @override
  final TileDownloader downloader;
  @override
  Widget buildTileLayer() => const SizedBox.shrink();
}

class FakeLocation implements LocationService {
  LocationResult result = const LocationFound(23.47, 120.96);
  @override
  Future<LocationResult> current() async => result;
}

OfflineRegion row(String id, String state, {int done = 0, int total = 100, double bytes = 0, String? error}) =>
    OfflineRegion(id: id, state: state, tilesDone: done, tilesTotal: total, bytes: bytes, error: error, updatedAt: DateTime(2026, 11, 22));

Future<void> openOffline(WidgetTester tester) async {
  await tester.tap(find.byTooltip('離線地圖'));
  await settle(tester);
}

void main() {
  group('offline sections', () {
    test('every region is in exactly one section', () {
      final s = buildOfflineSections([row('yushan', 'done', bytes: 5e6), row('xueba', 'downloading', done: 10), row('nanhu', 'queued'), row('nenggao', 'failed', error: 'x'), row('jiaming', 'interrupted', done: 40)]);
      expect(s.done.map((e) => e.def.id), ['yushan']);
      expect(s.active.map((e) => e.def.id), ['xueba', 'nanhu', 'jiaming', 'nenggao'], reason: 'running, waiting, then the ones needing a decision');
      expect(s.available.length, allOfflineRegions.length - 5);
      expect({...s.active, ...s.done, ...s.available}.length, allOfflineRegions.length);
    });

    test('progress and used space', () {
      final s = buildOfflineSections([row('yushan', 'done', bytes: 5e6), row('xueba', 'downloading', done: 25, total: 100, bytes: 2e6)]);
      expect(s.active.single.progress, 0.25);
      expect(s.usedBytes, 7e6);
      expect(buildOfflineSections(const []).usedBytes, 0);
      expect(OfflineEntry(taiwanBase, row('taiwan-base', 'downloading', done: 5, total: 0)).progress, 0, reason: 'unknown total is not a division by zero');
    });
  });

  group('peaksNear', () {
    Mountain peak(String id, double lat, double lng, int elev) => Mountain(
      id: id, name: id, nameEn: null, elevation: elev, region: 'r', latitude: lat, longitude: lng, category: MountainCategory.baiyue,
      trailGrade: null, beginnerFriendly: false, summary: '', permit: null, verified: false, sources: const [],
    );
    final xueshan = peak('xueshan', 24.3834, 121.2318, 3885);
    final north = peak('xueshan-north', 24.4147, 121.2404, 3703);
    final yushan = peak('yushan', 23.47, 120.957, 3952);
    final all = [xueshan, north, yushan];

    test('crowded peaks are grouped when zoomed out, separated when zoomed in', () {
      expect(peaksNear(all, xueshan.latitude, xueshan.longitude, 7.5).map((m) => m.id), ['xueshan', 'xueshan-north']);
      expect(peaksNear(all, xueshan.latitude, xueshan.longitude, 14).map((m) => m.id), ['xueshan'], reason: 'zoomed in they no longer overlap');
    });

    test('far away peaks are never grouped, and the highest comes first', () {
      expect(peaksNear(all, yushan.latitude, yushan.longitude, 6).map((m) => m.id), ['yushan']);
      expect(peaksNear(all, north.latitude, north.longitude, 7.5).first.id, 'xueshan');
    });
  });

  group('screens', () {
    late FakeDownloader dl;
    late FakeLocation location;

    Future<AppHarness> start(WidgetTester tester) {
      dl = FakeDownloader();
      location = FakeLocation();
      return AppHarness.start(
        tester,
        welcomeSeen: true,
        overrides: [
          tileCacheProvider.overrideWithValue(FakeTileCache(dl)),
          locationServiceProvider.overrideWithValue(location),
          exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf([m('yushan-main', '玉山', 3952, nameEn: 'Yushan'), m('xueshan-main', '雪山', 3885)]))),
        ],
      );
    }

    testWidgets('the map has one control group, the attribution, and shows the mountains', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await settle(tester);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byTooltip('我的位置'), findsOneWidget);
      expect(find.byTooltip('放大'), findsOneWidget);
      expect(find.byTooltip('縮小'), findsOneWidget);
      expect(find.byTooltip('離線地圖'), findsOneWidget);
      expect(find.textContaining('內政部國土測繪中心'), findsOneWidget);
      expect(find.byKey(const ValueKey('peak-yushan-main')), findsOneWidget);

      // The three buttons share one column, so they cannot overlap each other.
      final locate = tester.getRect(find.byTooltip('我的位置'));
      final zoomIn = tester.getRect(find.byTooltip('放大'));
      final zoomOut = tester.getRect(find.byTooltip('縮小'));
      expect(locate.overlaps(zoomIn) || zoomIn.overlaps(zoomOut) || locate.overlaps(zoomOut), isFalse);
      await app.dispose(tester);
    });

    testWidgets('locating shows the position, or explains why not', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await settle(tester);
      expect(find.byKey(const ValueKey('me')), findsNothing);

      await tester.tap(find.byTooltip('我的位置'));
      await settle(tester);
      expect(find.byKey(const ValueKey('me')), findsOneWidget);

      for (final (r, text) in [
        (const LocationDenied(), '需要位置權限才能顯示你的位置。'),
        (const LocationDenied(permanent: true), '位置權限已被關閉，請到系統設定開啟。'),
        (const LocationDisabled(), '手機的定位服務沒有開啟。'),
        (const LocationUnavailable(), '暫時抓不到位置，請到空曠處再試一次。'),
      ]) {
        location.result = r;
        await tester.tap(find.byTooltip('我的位置'));
        await settle(tester);
        expect(find.text(text), findsOneWidget);
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).hideCurrentSnackBar();
        await settle(tester);
      }
      await app.dispose(tester);
    });

    testWidgets('tapping a mountain offers its details (a crowded spot offers a choice)', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await settle(tester);
      await settleUntil(tester, find.byKey(const ValueKey('peak-yushan-main')));
      await tester.tap(find.byKey(const ValueKey('peak-yushan-main')));
      await settle(tester);
      // (In this test environment the camera is not realistic, so whether the tap offers one mountain or a
      // list of nearby ones is not asserted here; real positions are checked on a device in integration_test/map_test.dart.)
      final single = find.text('查看山岳資料');
      final list = find.textContaining('附近的山');
      expect(single.evaluate().isNotEmpty || list.evaluate().isNotEmpty, isTrue);
      if (single.evaluate().isNotEmpty) {
        await tapText(tester, '查看山岳資料');
      } else {
        await tester.tap(find.byKey(const ValueKey('near-xueshan-main')));
        await settle(tester);
      }
      expect(find.text('天氣預報'), findsOneWidget, reason: 'the mountain page of the explore tab');
      await app.dispose(tester);
    });

    testWidgets('offline maps: downloads, progress, queue, failure, and deleting all live on one screen', (tester) async {
      tester.view.physicalSize = const Size(800, 2600); // tall: the Rudy Map card above the list takes room
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await start(tester);
      await tapText(tester, '地圖');
      await openOffline(tester);

      expect(find.text('已下載 0 個區域，使用 0 KB'), findsOneWidget);
      expect(find.byKey(const ValueKey('available-yushan')), findsOneWidget);
      expect(find.byKey(const ValueKey('available-taiwan-base')), findsOneWidget);

      Future<void> download(String id) async {
        await tester.tap(find.descendant(of: find.byKey(ValueKey('available-$id')), matching: find.text('下載')));
        await settle(tester);
      }

      await download('yushan');
      await download('xueba');
      expect(find.text('下載中與待處理'), findsOneWidget);
      expect(find.byKey(const ValueKey('active-yushan')), findsOneWidget);
      expect(find.text('等待中'), findsOneWidget, reason: 'the second one waits for the first');
      expect(find.byKey(const ValueKey('available-nanhu')), findsOneWidget, reason: 'a running download does not hide what else can be downloaded');

      dl.progress('yushan', 350, 700, 4e6);
      await settle(tester);
      expect(find.text('下載中 50%（3.8 MB）'), findsOneWidget);

      // Leave the screen and come back: the progress is still there.
      await tester.pageBack();
      await settle(tester);
      expect(find.byType(Badge), findsOneWidget);
      await openOffline(tester);
      expect(find.text('下載中 50%（3.8 MB）'), findsOneWidget);

      await dl.finish('yushan');
      await settle(tester);
      expect(find.byKey(const ValueKey('done-yushan')), findsOneWidget);
      expect(find.text('已下載 1 個區域，使用 3.8 MB'), findsOneWidget);
      expect(find.text('下載中 0%（0 KB）'), findsOneWidget, reason: 'the queue moved on to xueba');

      dl.fail('xueba', Exception('伺服器沒有回應'));
      await settle(tester);
      expect(find.textContaining('下載失敗：Exception: 伺服器沒有回應'), findsOneWidget);
      await tapText(tester, '重試');
      expect(dl.started, ['yushan', 'xueba', 'xueba']);

      await tester.tap(find.byTooltip('刪除 玉山'));
      await settle(tester);
      await tapText(tester, '刪除');
      expect(find.byKey(const ValueKey('done-yushan')), findsNothing);
      expect(find.byKey(const ValueKey('available-yushan')), findsOneWidget);
      expect(dl.deleted, contains('yushan'));
      await app.dispose(tester);
    });
  });
}
