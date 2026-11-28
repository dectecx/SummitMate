
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

    Future<AppHarness> start(WidgetTester tester, {bool installed = false, String? saved, bool online = true}) async {
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
          if (!online) onlineProvider.overrideWithValue(false),
          exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf([m('yushan-main', '玉山', 3952), m('xueshan-main', '雪山', 3885)]))),
        ],
      );
      if (saved != null) await real(tester, () => app.container.read(settingsStoreProvider).set(mapSourceKey, saved));
      return app;
    }

    Future<void> openOfflineMaps(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('map-layers')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-offline')));
      await settle(tester);
    }

    testWidgets('the card offers the download, shows progress, and the switch appears when it is done', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await openOfflineMaps(tester);

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
      await openOfflineMaps(tester);
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
      await openOfflineMaps(tester);
      installer.emit(const RudyInstallState(RudyInstallPhase.unavailable, error: '魯地圖檔案目前還沒有開放下載'));
      await settle(tester);
      expect(find.textContaining('還沒有開放下載'), findsOneWidget);
      expect(find.text('重試'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('without the files the government map is shown with an offer to download the Rudy Map', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await settle(tester);
      expect(find.byKey(fakeRudyMapKey), findsNothing);
      expect(find.byKey(const ValueKey('rudy-prompt')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rudy-prompt-download')));
      await settle(tester);
      expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget, reason: 'landed on the offline maps page');
      await app.dispose(tester);
    });

    testWidgets('declining the offer keeps the government map and stops asking', (tester) async {
      final app = await start(tester);
      await tapText(tester, '地圖');
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('rudy-prompt-decline')));
      await settle(tester);
      expect(find.byKey(const ValueKey('rudy-prompt')), findsNothing);
      expect(app.container.read(mapSourceProvider), MapSource.nlsc);

      // Choosing it later in the settings leads to the download.
      await tester.tap(find.byKey(const ValueKey('map-layers')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('base-rudy')));
      await settle(tester);
      expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('with no connection the installed Rudy Map stands in for the government map', (tester) async {
      final app = await start(tester, installed: true, saved: 'nlsc', online: false);
      await tapText(tester, '地圖');
      await settle(tester);
      expect(find.byKey(fakeRudyMapKey), findsOneWidget);
      expect(find.text('魯地圖・離線'), findsOneWidget);
      expect(app.container.read(mapSourceProvider), MapSource.nlsc, reason: 'the choice is kept for when there is a connection');
      await app.dispose(tester);
    });

    testWidgets('with the files installed the Rudy Map is shown first, with a compass when turned', (tester) async {
      final app = await start(tester, installed: true);
      await tapText(tester, '地圖');
      await settle(tester);
      expect(find.byKey(fakeRudyMapKey), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('map-layers')), matching: find.text('魯地圖')), findsOneWidget);
      expect(find.byKey(const ValueKey('rudy-prompt')), findsNothing);
      expect(find.textContaining('© OpenStreetMap contributors'), findsOneWidget, reason: 'seen as soon as the map appears');
      await tester.tap(find.byKey(const ValueKey('map-credit')));
      await settle(tester);
      expect(find.textContaining('魯地圖 Rudy Map'), findsOneWidget, reason: 'the full credit');
      expect(find.byKey(const ValueKey('map-osm-link')), findsOneWidget);
      await tapText(tester, '關閉');

      handle.northValue.value = 40;
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-compass')));
      await settle(tester);
      expect(find.byKey(const ValueKey('map-compass')), findsNothing);

      await tester.tap(find.byTooltip('我的位置'));
      await settle(tester);
      expect(handle.calls, containsAll(['north', 'me', 'move']));

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
      expect(find.text('地圖：內政部國土測繪中心'), findsOneWidget);
      expect(find.byKey(const ValueKey('rudy-prompt')), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
