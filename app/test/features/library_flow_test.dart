import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/gear/providers.dart';
import 'package:summitmate/features/library/providers.dart';
import 'package:summitmate/features/meals/providers.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'harness.dart';

final _now = DateTime(2026, 5, 10, 9);

Future<AppHarness> start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => _now)]);
}

Future<String> trip(WidgetTester tester, AppHarness app, String name) async {
  final id = await act(tester, () => app.container.read(tripRepositoryProvider).create(name: name, start: DateTime(2026, 5, 10), end: DateTime(2026, 5, 11)));
  await settle(tester);
  return id;
}

void main() {
  testWidgets('new gear is remembered in the library, shows up as a suggestion next time, and can be edited there', (tester) async {
    final app = await start(tester);
    await trip(tester, app, '庫測試');
    await tapText(tester, '庫測試');
    await tapText(tester, '裝備');
    await tapText(tester, '新增裝備');
    await enter(tester, '名稱', '睡袋');
    await enter(tester, '單件重量', '900');
    await tapText(tester, '新增');

    final library = await real(tester, () => app.db.select(app.db.libraryItems).get());
    expect(library.map((i) => [i.kind, i.name, i.weight]), [['gear', '睡袋', 900.0]]);

    // Typing a part of the name offers it, and choosing it fills in the weight.
    await tapText(tester, '新增裝備');
    await enter(tester, '名稱', '睡');
    await settle(tester);
    final chip = find.byKey(ValueKey('lib-${library.single.id}'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await settle(tester);
    expect(find.widgetWithText(TextFormField, '900'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sheet-close'))); // swiping or tapping outside no longer closes it
    await settle(tester);

    // The library page lists it and the item can be edited.
    await tester.pageBack();
    await settle(tester);
    await tapText(tester, '我');
    await tapText(tester, '我的裝備庫');
    expect(find.text('睡袋'), findsOneWidget);
    await tapText(tester, '睡袋');
    await enter(tester, '單件重量', '850');
    await tapText(tester, '儲存');
    expect((await real(tester, () => app.db.select(app.db.libraryItems).getSingle())).weight, 850.0);
    await app.dispose(tester);
  });

  testWidgets('food is remembered separately, and the library page can add an item by hand', (tester) async {
    final app = await start(tester);
    await trip(tester, app, '食物庫');
    await tapText(tester, '食物庫');
    await tapText(tester, '餐食');
    await tapText(tester, '新增餐點');
    await enter(tester, '名稱', '燕麥粥');
    await enter(tester, '單份熱量', '300');
    await tapText(tester, '新增');
    final rows = await real(tester, () => app.db.select(app.db.libraryItems).get());
    expect(rows.map((r) => [r.kind, r.name, r.calories]), [['meal', '燕麥粥', 300.0]]);

    await tester.pageBack();
    await settle(tester);
    await tapText(tester, '我');
    await tapText(tester, '我的裝備庫');
    await tapText(tester, '食物');
    expect(find.text('燕麥粥'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-add')));
    await settle(tester);
    await enter(tester, '名稱', '乾燥飯');
    await tapText(tester, '新增');
    expect((await real(tester, () => app.db.select(app.db.libraryItems).get())).length, 2);
    await app.dispose(tester);
  });

  testWidgets('a trip is saved as a template and applied to another trip from the menu', (tester) async {
    final app = await start(tester);
    final a = await trip(tester, app, '來源行程');
    await act(tester, () async {
      await app.container.read(gearRepositoryProvider).add(a, name: '睡袋', weight: 900, category: 'sleep');
      await app.container.read(mealRepositoryProvider).add(a, dayIndex: 1, name: '飯糰', mealType: 'lunch', weight: 180, calories: 320);
    });
    await trip(tester, app, '目標行程');
    await settle(tester);

    await tapText(tester, '來源行程');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '存成範本');
    await tapText(tester, '儲存');
    expect(find.textContaining('已存成範本'), findsOneWidget);
    expect((await real(tester, () => app.db.select(app.db.templates).get())).single.title, '來源行程');
    await tester.pageBack();
    await settle(tester);

    await tapText(tester, '目標行程');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '套用範本');
    final templateId = (await real(tester, () => app.db.select(app.db.templates).getSingle())).id;
    await tester.tap(find.byKey(ValueKey('apply-$templateId')));
    await settleUntil(tester, find.textContaining('已加入'));
    expect(find.textContaining('已加入 裝備 1 件、餐點 1 項'), findsOneWidget);
    final gear = await real(tester, () => app.db.select(app.db.gearItems).get());
    expect(gear.map((g) => [g.name, g.tripId]), containsAll([['睡袋', a], ['睡袋', isNot(a)]]));
    await app.dispose(tester);
  });

  testWidgets('applying a template offers a trip added after the trips tab went out of view', (tester) async {
    final app = await start(tester);
    final id = await act(tester, () => app.container.read(templateRepositoryProvider).create(title: '夏季兩天', items: const []));
    await settle(tester);
    await tapText(tester, '我');
    final tripId = await trip(tester, app, '後來的行程');
    await tapText(tester, '我的範本');
    await tapText(tester, '夏季兩天');
    await tester.tap(find.byKey(const ValueKey('template-apply')));
    await settle(tester);
    expect(find.byKey(ValueKey('apply-trip-$tripId')), findsOneWidget, reason: 'template $id');
    await app.dispose(tester);
  });

  testWidgets('the templates page lists templates, shows the content, renames and deletes', (tester) async {
    final app = await start(tester);
    final id = await act(tester, () => app.container.read(templateRepositoryProvider).create(title: '夏季兩天', items: const []));
    await settle(tester);
    await tapText(tester, '我');
    await tapText(tester, '我的範本');
    expect(find.byKey(ValueKey('template-$id')), findsOneWidget);
    await tapText(tester, '夏季兩天');
    expect(find.byKey(const ValueKey('template-apply')), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '改名');
    await tester.enterText(find.byType(TextField).last, '冬季兩天');
    await tapText(tester, '儲存');
    expect((await real(tester, () => app.db.select(app.db.templates).getSingle())).title, '冬季兩天');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '刪除範本');
    await tapText(tester, '刪除');
    expect(await real(tester, () => app.db.select(app.db.templates).get()), isEmpty);
    await app.dispose(tester);
  });
}
