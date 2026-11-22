import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';

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
}
