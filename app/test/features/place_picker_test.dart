import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/gpx/domain/gpx_models.dart';
import 'package:summitmate/features/trips/domain/gpx_trip.dart';
import 'package:summitmate/features/map/rudy/rudy_installer.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';
import 'rudy_fakes.dart';

final _list = [
  m('yushan-main', '玉山', 3952, nameEn: 'Yushan'),
  m('yushan-east', '玉山東峰', 3873),
  m('xueshan-main', '雪山', 3885, region: '雪霸國家公園'),
];

Future<AppHarness> start(WidgetTester tester, {FakeExploreApi? api}) async {
  final app = await AppHarness.start(
    tester,
    welcomeSeen: true,
    overrides: [exploreApiProvider.overrideWithValue(api ?? FakeExploreApi(payloadOf(_list))), clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))],
  );
  await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '地點測試', start: DateTime(2026, 5, 10)));
  await settle(tester);
  await tapText(tester, '地點測試');
  await tapText(tester, '新增節點');
  return app;
}

Future<void> typeName(WidgetTester tester, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, '名稱'), text);
  await settleUntil(tester, find.byKey(const ValueKey('place-yushan-main')), tries: 3);
  await settle(tester);
}

bool noSuggestions() => ['yushan-main', 'yushan-east', 'xueshan-main'].every((id) => find.byKey(ValueKey('place-$id')).evaluate().isEmpty);

void main() {
  testWidgets('typing a mountain name offers places; choosing one fills in the node', (tester) async {
    final app = await start(tester);
    await typeName(tester, '玉山');

    expect(find.byKey(const ValueKey('place-yushan-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('place-yushan-east')), findsOneWidget);
    expect(find.byKey(const ValueKey('place-xueshan-main')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('place-yushan-main')));
    await settle(tester);

    expect(find.byKey(const ValueKey('place-chip')), findsOneWidget);
    expect(find.text('地點：玉山'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '3952'), findsOneWidget, reason: 'the elevation is filled in');
    expect(find.byKey(const ValueKey('place-yushan-east')), findsNothing, reason: 'the list closes after choosing');

    await tapText(tester, '新增');
    final row = (await real(tester, () => app.db.select(app.db.itineraryItems).get())).single;
    expect([row.name, row.altitude, row.lat, row.lng], ['玉山', 3952, 23.47, 120.96], reason: 'the coordinates come from the mountain list');
    await app.dispose(tester);
  });

  testWidgets('search also matches the region and English name, and nothing matches nonsense', (tester) async {
    final app = await start(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '名稱'), '雪霸');
    await settleUntil(tester, find.byKey(const ValueKey('place-xueshan-main')));
    expect(find.byKey(const ValueKey('place-xueshan-main')), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '名稱'), 'yushan');
    await settleUntil(tester, find.byKey(const ValueKey('place-yushan-main')));
    expect(find.byKey(const ValueKey('place-yushan-main')), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '名稱'), '向陽山屋');
    await settle(tester);
    expect(noSuggestions(), isTrue, reason: 'a hut is not in the mountain list; typing a plain name still works');
    await tapText(tester, '新增');
    final row = (await real(tester, () => app.db.select(app.db.itineraryItems).get())).single;
    expect([row.name, row.lat, row.lng], ['向陽山屋', null, null]);
    await app.dispose(tester);
  });

  testWidgets('an altitude the person already typed is kept, and the chip removes the place again', (tester) async {
    final app = await start(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '海拔'), '3000');
    await typeName(tester, '玉山');
    await tester.tap(find.byKey(const ValueKey('place-yushan-main')));
    await settle(tester);
    expect(find.widgetWithText(TextFormField, '3000'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '3952'), findsNothing);

    await tester.tap(find.byTooltip('移除地點'));
    await settle(tester);
    expect(find.byKey(const ValueKey('place-chip')), findsNothing);
    await tapText(tester, '新增');
    final row = (await real(tester, () => app.db.select(app.db.itineraryItems).get())).single;
    expect([row.name, row.altitude, row.lat, row.lng], ['玉山', 3000, null, null]);
    await app.dispose(tester);
  });

  testWidgets('an existing node with coordinates shows them as a place that can be removed', (tester) async {
    final app = await start(tester);
    await typeName(tester, '玉山');
    await tester.tap(find.byKey(const ValueKey('place-yushan-main')));
    await settle(tester);
    await tapText(tester, '新增');

    await tapText(tester, '玉山');
    expect(find.byKey(const ValueKey('place-chip')), findsOneWidget);
    expect(find.textContaining('已設定座標'), findsOneWidget, reason: 'a saved node remembers the coordinates, not which list entry they came from');
    await tester.tap(find.byTooltip('移除地點'));
    await settle(tester);
    await tapText(tester, '儲存');
    final row = (await real(tester, () => app.db.select(app.db.itineraryItems).get())).single;
    expect([row.lat, row.lng], [null, null]);
    await app.dispose(tester);
  });

  testWidgets('without the mountain list (first launch offline) the name field simply works', (tester) async {
    final api = FakeExploreApi(payloadOf(_list))..failWith = Exception('offline');
    final app = await start(tester, api: api);
    await tester.enterText(find.widgetWithText(TextFormField, '名稱'), '玉山');
    await settle(tester);
    expect(noSuggestions(), isTrue);
    await tapText(tester, '新增');
    expect((await real(tester, () => app.db.select(app.db.itineraryItems).get())).single.name, '玉山');
    await app.dispose(tester);
  });

  testWidgets('a trip can be given a main mountain from a searchable list, and clear it again', (tester) async {
    final app = await AppHarness.start(
      tester,
      welcomeSeen: true,
      overrides: [exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf(_list))), clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))],
    );
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '主山頭', start: DateTime(2026, 5, 10)));
    await settle(tester);
    await tapText(tester, '主山頭');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '編輯行程');
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('trip-mountain')));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, '搜尋山名'), '雪山');
    await settle(tester);
    expect(find.byKey(const ValueKey('trip-mountain-yushan-main')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('trip-mountain-xueshan-main')));
    await settle(tester);
    expect(find.textContaining('雪山  ·  3885 m'), findsOneWidget);

    await tapText(tester, '儲存');
    expect((await real(tester, () => app.db.select(app.db.trips).getSingle())).mountainId, 'xueshan-main');
    await app.dispose(tester);
  });

  testWidgets('a trip with a main mountain reminds to download the Rudy Map and opens the offline maps page', (tester) async {
    final app = await AppHarness.start(
      tester,
      welcomeSeen: true,
      overrides: [exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf(_list))), clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))],
    );
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '離線提醒', start: DateTime(2026, 5, 10), mountainId: 'yushan-main'));
    await settle(tester);
    await tapText(tester, '離線提醒');
    expect(find.byKey(const ValueKey('trip-offline-hint')), findsOneWidget);
    expect(find.text('出發前先下載魯地圖離線地圖，山上沒有訊號也能看'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trip-offline-download')));
    await settle(tester);
    expect(find.byKey(const ValueKey('rudy-card')), findsOneWidget, reason: 'landed on the offline maps page');
    await app.dispose(tester);
  });

  testWidgets('the Rudy Map reminder is not shown without a mountain, after the trip, or once the map is installed', (tester) async {
    tester.view.physicalSize = const Size(800, 2000); // tall: all three trips are on screen
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final installer = FakeRudyInstaller();
    final app = await AppHarness.start(
      tester,
      welcomeSeen: true,
      rudy: installer,
      overrides: [exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf(_list))), clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))],
    );
    final trips = app.container.read(tripRepositoryProvider);
    await act(tester, () async {
      await trips.create(name: '沒有山頭', start: DateTime(2026, 5, 10));
      await trips.create(name: '已經結束', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 2), mountainId: 'yushan-main');
      await trips.create(name: '還沒出發', start: DateTime(2026, 5, 20), mountainId: 'yushan-main');
    });
    await settle(tester);

    for (final name in ['沒有山頭', '已經結束']) {
      await tapText(tester, name);
      expect(find.byKey(const ValueKey('trip-offline-hint')), findsNothing, reason: name);
      await tester.pageBack();
      await settle(tester);
    }

    await tapText(tester, '還沒出發');
    expect(find.byKey(const ValueKey('trip-offline-hint')), findsOneWidget);
    await act(tester, () async => installer.emit(const RudyInstallState(RudyInstallPhase.done, progress: 1)));
    await settle(tester);
    expect(find.byKey(const ValueKey('trip-offline-hint')), findsNothing, reason: 'already on the phone');
    await app.dispose(tester);
  });

  testWidgets('route points come only from trips to the same mountain, most used first, and fill the node', (tester) async {
    final app = await AppHarness.start(
      tester,
      welcomeSeen: true,
      overrides: [exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf(_list))), clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))],
    );
    final trips = app.container.read(tripRepositoryProvider);
    final items = app.container.read(itineraryRepositoryProvider);
    await act(tester, () async {
      final a = await trips.create(name: '玉山舊', start: DateTime(2026, 4, 1), mountainId: 'yushan-main');
      final b = await trips.create(name: '雪山舊', start: DateTime(2026, 4, 2), mountainId: 'xueshan-main');
      await items.add(a, dayIndex: 1, name: '黑水塘', altitude: 2700);
      await items.add(a, dayIndex: 1, name: '涼亭');
      await items.add(a, dayIndex: 2, name: '黑水塘', altitude: 2710);
      await items.add(b, dayIndex: 1, name: '雪山獨有');
      await trips.create(name: '玉山新', start: DateTime(2026, 5, 10), mountainId: 'yushan-main');
      await trips.create(name: '沒山頭', start: DateTime(2026, 5, 11));
    });
    await settle(tester);

    await tapText(tester, '沒山頭');
    await tapText(tester, '新增節點');
    expect(find.byType(ActionChip), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sheet-close'))); // swiping or tapping outside no longer closes it
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    await tapText(tester, '玉山新');
    await tapText(tester, '新增節點');
    await settle(tester);
    expect(find.byKey(const ValueKey('route-point-黑水塘')), findsOneWidget);
    expect(find.byKey(const ValueKey('route-point-涼亭')), findsOneWidget);
    expect(find.byKey(const ValueKey('route-point-雪山獨有')), findsNothing, reason: 'other mountains do not leak in');
    expect(tester.getTopLeft(find.byKey(const ValueKey('route-point-黑水塘'))).dx, lessThan(tester.getTopLeft(find.byKey(const ValueKey('route-point-涼亭'))).dx), reason: 'most used first');

    await tester.tap(find.byKey(const ValueKey('route-point-黑水塘')));
    await settle(tester);
    expect(find.widgetWithText(TextFormField, '黑水塘'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2710'), findsOneWidget, reason: 'the altitude used last time');
    expect(find.byKey(const ValueKey('route-point-黑水塘')), findsNothing, reason: 'already chosen');
    await app.dispose(tester);
  });

  testWidgets('a trip with a stored track shows its elevation profile with totals', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))]);
    final track = encodeTrack([for (var i = 0; i < 40; i++) GpxPoint(lat: 23.3 + i * 0.001, lng: 121.0, ele: 2000 + i * 20.0)]);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '有軌跡', start: DateTime(2026, 5, 10), track: track));
    await settle(tester);
    expect(find.byKey(const ValueKey('import-gpx')), findsOneWidget);
    await tapText(tester, '有軌跡');
    expect(find.byKey(const ValueKey('track-profile')), findsOneWidget);
    expect(find.textContaining('爬升 780 m'), findsOneWidget);
    expect(find.textContaining('最高 2780 m'), findsOneWidget);
    await app.dispose(tester);
  });
}
