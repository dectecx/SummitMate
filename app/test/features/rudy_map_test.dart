
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/map/maplibre/rudy_providers.dart';
import 'package:summitmate/features/map/maplibre/rudy_style.dart';
import 'package:summitmate/features/map/providers.dart';
import 'package:summitmate/features/map/rudy/rudy_installer.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';
import 'map_flow_test.dart' show FakeLocation;
import 'rudy_fakes.dart';

void main() {
  test('the style template gets file URIs, with spaces and Chinese characters escaped', () {
    final s = fillRudyStyle('{"u":"pmtiles://{{PMTILES}}","g":"{{GLYPHS}}/{fontstack}/{range}.pbf"}', pmtilesPath: '/data/Application Support/rudy/map.pmtiles', glyphsDir: '/data/Application Support/rudy/glyphs');
    expect(s, contains('pmtiles://file:///data/Application%20Support/rudy/map.pmtiles'));
    expect(s, contains('file:///data/Application%20Support/rudy/glyphs/{fontstack}/{range}.pbf'), reason: 'the MapLibre placeholders stay untouched');
    expect(s.contains('{{'), isFalse);
  });

  group('screens', () {
    late FakeRudyInstaller installer;
    late FakeMapHandle handle;
    late FakeLocation location;

    Future<AppHarness> start(WidgetTester tester, {bool installed = false, String? saved}) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      installer = FakeRudyInstaller()..installed = installed;
      handle = FakeMapHandle();
      location = FakeLocation();
      final app = await AppHarness.start(
        tester,
        welcomeSeen: true,
        rudy: installer,
        mapHandle: handle,
        overrides: [
          locationServiceProvider.overrideWithValue(location),
          exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf([m('yushan-main', '玉山', 3952), m('xueshan-main', '雪山', 3885)]))),
        ],
      );
      if (saved != null) await real(tester, () => app.container.read(settingsStoreProvider).set(mapSourceKey, saved));
      return app;
    }

    testWidgets('the card offers the download, shows progress, and the switch appears when it is done', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await tester.tap(find.byTooltip('離線地圖'));
      await settle(tester);

      expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('rudy-use')), findsNothing, reason: 'nothing to use before it is downloaded');
      await tester.tap(find.byKey(const ValueKey('rudy-credit')));
      await settle(tester);
      expect(find.textContaining('rudymap.tw'), findsWidgets, reason: 'the author is credited with the link');
      await tester.tap(find.byKey(const ValueKey('rudy-credit')));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('rudy-download')));
      await settle(tester);
      expect(installer.starts, 1);
      expect(find.byKey(const ValueKey('rudy-progress')), findsOneWidget);
      expect(find.textContaining('下載地圖中 10%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rudy-cancel')));
      await settle(tester);
      expect(installer.cancels, 1);
      expect(find.byKey(const ValueKey('rudy-download')), findsOneWidget);

      installer.emit(const RudyInstallState(RudyInstallPhase.done, progress: 1));
      await settle(tester);
      expect(find.byKey(const ValueKey('rudy-use')), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('deleting the downloaded map brings the download button back', (tester) async {
      final app = await start(tester, installed: true, saved: 'rudy');
      await tapText(tester, '地圖');
      await tester.tap(find.byTooltip('離線地圖'));
      await settle(tester);
      expect(find.byKey(const ValueKey('rudy-use')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rudy-remove')));
      await settle(tester);
      await tapText(tester, '刪除');
      await settle(tester);
      expect(installer.removes, 1);
      expect(find.byKey(const ValueKey('rudy-download')), findsOneWidget, reason: 'not downloaded any more');
      expect(find.byKey(const ValueKey('rudy-use')), findsNothing);
      expect(app.container.read(mapSourceProvider), MapSource.nlsc, reason: 'the map falls back to the government map');
      await app.dispose(tester);
    });

    testWidgets('when the file is not offered yet the card says so and offers a retry', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await tester.tap(find.byTooltip('離線地圖'));
      await settle(tester);
      installer.emit(const RudyInstallState(RudyInstallPhase.unavailable, error: '魯地圖檔案目前還沒有開放下載'));
      await settle(tester);
      expect(find.textContaining('還沒有開放下載'), findsOneWidget);
      expect(find.text('重試'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('choosing the Rudy Map before it is downloaded sends the person to the download', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await tester.tap(find.byKey(const ValueKey('map-source')));
      await settle(tester);
      await tapText(tester, '魯地圖（登山地形圖）');
      expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget, reason: 'landed on the offline maps page');
      expect(app.container.read(mapSourceProvider), MapSource.nlsc);
      await app.dispose(tester);
    });

    testWidgets('with the files installed the map switches to the Rudy Map and its controls work', (tester) async {
      final app = await start(tester, installed: true);
      await tapText(tester, '地圖');
      await tester.tap(find.byKey(const ValueKey('map-source')));
      await settle(tester);
      await tapText(tester, '魯地圖（登山地形圖）');
      await settle(tester);
      expect(app.container.read(mapSourceProvider), MapSource.rudy);
      expect(find.byKey(fakeRudyMapKey), findsOneWidget);
      await tester.tap(find.byTooltip('地圖資料來源'));
      await settle(tester);
      expect(find.textContaining('魯地圖 Rudy Map'), findsOneWidget, reason: 'the required credit is one tap away');
      expect(find.textContaining('內政部國土測繪中心（政府資料'), findsNothing);
      await tapText(tester, '關閉');

      await tester.tap(find.byTooltip('放大'));
      await tester.tap(find.byTooltip('我的位置'));
      await settle(tester);
      expect(handle.calls, containsAll(['zoom:0.5', 'me', 'move']));

      // Tapping on the map offers the mountains near the tap (give the mountain list time to load first).
      await real(tester, () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await settle(tester);
      await tester.tap(find.byKey(fakeRudyMapKey), warnIfMissed: false);
      await settle(tester);
      expect(find.textContaining('附近的山（2）'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('the choice is remembered, and without the files the government map is shown', (tester) async {
      final app = await start(tester, installed: false, saved: 'rudy');
      await tapText(tester, '地圖');
      await settle(tester);
      expect(find.byKey(fakeRudyMapKey), findsNothing, reason: 'chosen but not installed: fall back instead of a blank map');
      await tester.tap(find.byTooltip('地圖資料來源'));
      await settle(tester);
      expect(find.textContaining('內政部國土測繪中心'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
