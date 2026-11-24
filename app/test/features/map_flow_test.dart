import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/map/data/location_service.dart';
import 'package:summitmate/features/explore/domain/mountain_models.dart';
import 'package:summitmate/features/map/domain/map_logic.dart';
import 'package:summitmate/features/map/providers.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';

class FakeLocation implements LocationService {
  LocationResult result = const LocationFound(23.47, 120.96);
  @override
  Future<LocationResult> current() async => result;
}

void main() {
  test('sizes are shown the way people read them', () {
    expect(formatBytes(512 * 1024), '512 KB');
    expect(formatBytes(3.8 * 1024 * 1024), '3.8 MB');
    expect(formatBytes(410 * 1024 * 1024), '410 MB');
    expect(formatBytes(1.3 * 1024 * 1024 * 1024), '1.3 GB');
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
    late FakeLocation location;

    Future<AppHarness> start(WidgetTester tester) {
      location = FakeLocation();
      return AppHarness.start(
        tester,
        welcomeSeen: true,
        overrides: [
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

    testWidgets('the offline maps page is just the Rudy Map card', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await tester.tap(find.byTooltip('離線地圖'));
      await settle(tester);

      expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('rudy-download')), findsOneWidget);
      expect(find.textContaining('國土測繪中心'), findsNothing, reason: 'no region downloads of the government map any more');
      await app.dispose(tester);
    });
  });
}
