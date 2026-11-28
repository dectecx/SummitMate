import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/gpx/providers.dart';
import 'package:summitmate/features/trips/domain/track_codec.dart';
import 'package:summitmate/features/trips/providers.dart';

import '../harness.dart';
import '../rudy_fakes.dart';
import 'sample_gpx.dart';

void main() {
  late Directory dir;
  late FakeMapHandle handle;

  Future<AppHarness> start(WidgetTester tester, {bool installed = true}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dir = Directory.systemTemp.createTempSync('sm_route_flow');
    addTearDown(() => dir.deleteSync(recursive: true));
    handle = FakeMapHandle();
    return AppHarness.start(
      tester,
      welcomeSeen: true,
      rudy: FakeRudyInstaller()..installed = installed,
      mapHandle: handle,
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9)),
        gpxDirectoryProvider.overrideWithValue(() async => dir),
        gpxPickerProvider.overrideWithValue(() async => (bytes: sampleGpx(), name: 'walk.gpx')),
      ],
    );
  }

  Future<void> importAndOpen(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('route-import')));
    await settle(tester);
    await settleUntil(tester, find.textContaining('占用'));
    await tester.tap(find.text('向陽山屋'));
    await settle(tester);
  }

  testWidgets('a GPX file is imported on the map, drawn, and read along its height chart', (tester) async {
    final app = await start(tester);
    await tapText(tester, '地圖');
    await settle(tester);
    await tester.tap(find.byTooltip('我的路線'));
    await settle(tester);
    expect(find.textContaining('還沒有路線'), findsOneWidget);

    await importAndOpen(tester);
    await settleUntil(tester, find.byKey(const ValueKey('route-panel')));
    expect(handle.calls, contains('route:5'));
    expect(find.text('↑ 600 m'), findsOneWidget);
    expect(handle.cursor, isNull);

    final chart = find.byKey(const ValueKey('elevation-scrub'));
    await tester.tapAt(tester.getRect(chart).centerRight - const Offset(2, 0));
    await settle(tester);
    expect(handle.cursor!.lat, closeTo(23.296, .0001), reason: 'the end of the walk');
    expect(find.textContaining('2,900 m'), findsOneWidget);
    expect(find.textContaining('4 小時 0 分'), findsOneWidget);
    await tester.drag(chart, const Offset(-600, 0));
    await settle(tester);
    expect(handle.cursor!.lat, closeTo(23.28, .0001), reason: 'dragged back to the start');

    await tester.tap(find.byKey(const ValueKey('route-collapse')));
    await settle(tester);
    expect(chart, findsNothing);
    await tester.tap(find.byTooltip('不顯示路線'));
    await settle(tester);
    expect(find.byKey(const ValueKey('route-panel')), findsNothing);
    expect(handle.calls.last, 'route:0');

    // The same file again is recognised.
    await tester.tap(find.byTooltip('我的路線'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('route-import')));
    await settle(tester);
    await settleUntil(tester, find.textContaining('已經匯入過'));
    await app.dispose(tester);
  });

  testWidgets('on the government map a route is not drawn: the Rudy Map is offered instead', (tester) async {
    final app = await start(tester, installed: false);
    await tapText(tester, '地圖');
    await settle(tester);
    await tester.tap(find.byTooltip('我的路線'));
    await settle(tester);
    await importAndOpen(tester);
    await settleUntil(tester, find.byKey(const ValueKey('route-needs-rudy')));
    expect(find.byKey(const ValueKey('route-panel')), findsNothing);
    expect(find.byKey(const ValueKey('rudy-prompt')), findsNothing, reason: 'one card at a time');
    await tester.tap(find.byKey(const ValueKey('route-switch')));
    await settle(tester);
    expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget, reason: 'to the download');
    await app.dispose(tester);
  });

  testWidgets('a saved route is attached to a trip as a copy, and can be taken off', (tester) async {
    final app = await start(tester);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '週末', start: DateTime(2026, 5, 10)));
    await settle(tester);
    await tapText(tester, '週末');
    await tester.tap(find.byTooltip('更多'));
    await settle(tester);
    expect(find.text('匯出 GPX'), findsNothing);
    expect(find.text('移除路線'), findsNothing);
    await tapText(tester, '附加路線');
    await importAndOpen(tester);
    await settleUntil(tester, find.byKey(const ValueKey('track-profile')));
    final saved = (await real(tester, () => app.db.select(app.db.trips).getSingle())).track;
    expect(decodeTrack(saved), hasLength(5));
    expect(await real(tester, () => app.db.select(app.db.itineraryItems).get()), isEmpty, reason: 'a route never becomes itinerary nodes');

    await tester.tap(find.byTooltip('更多'));
    await settle(tester);
    await tapText(tester, '移除路線');
    expect(find.byKey(const ValueKey('track-profile')), findsNothing);
    await app.dispose(tester);
  });
}
