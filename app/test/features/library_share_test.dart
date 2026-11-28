import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/features/library/data/shared_sets_api.dart';
import 'package:summitmate/features/library/domain/set_item.dart';
import 'package:summitmate/features/library/providers.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'harness.dart';

SharedSetSummary summary(String id, String title, {SharedVisibility v = SharedVisibility.public, bool mine = false}) =>
    SharedSetSummary(id: id, title: title, authorName: '山友', visibility: v, totalWeight: 3200, gearCount: 2, mealCount: 1, createdAt: DateTime(2026, 5, 1), mine: mine);

const items = [
  SetItem(kind: 'gear', name: '睡袋', category: 'sleep', weight: 900),
  SetItem(kind: 'gear', name: '爐頭', category: 'cook', weight: 380, quantity: 2),
  SetItem(kind: 'meal', name: '飯糰', category: 'lunch', weight: 180, calories: 320, day: 1),
];

class FakeSharedSets implements SharedSetsApi {
  final public = [summary('p1', '百岳輕量化'), summary('k1', '嘉明湖冬季', v: SharedVisibility.protected)];
  final mine = [summary('m1', '我的組合', mine: true)];
  final created = <({String title, SharedVisibility visibility, String? key, int count})>[];
  final deleted = <String>[];
  final keysTried = <String?>[];
  bool offline = false;

  @override
  Future<SharedSetPage> list({required String scope, String q = '', String? cursor}) async {
    if (offline) throw const SharedSetsException(code: 'network');
    final all = scope == 'mine' ? mine : public;
    return SharedSetPage([for (final s in all) if (q.isEmpty || s.title.contains(q)) s], null);
  }

  @override
  Future<SharedSetDetail> get(String id, {String? key}) async {
    keysTried.add(key);
    final s = [...public, ...mine].firstWhere((s) => s.id == id);
    if (s.visibility == SharedVisibility.protected && !s.mine) {
      if (key == null) throw const SharedSetsException(code: 'access_key_required', status: 403);
      if (key != 'abcd') throw const SharedSetsException(code: 'invalid_access_key', status: 403);
    }
    return SharedSetDetail(s, items);
  }

  @override
  Future<SharedSetSummary> create({required String title, required SharedVisibility visibility, String? key, required List<SetItem> items}) async {
    created.add((title: title, visibility: visibility, key: key, count: items.length));
    return summary('new', title, v: visibility, mine: true);
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

Future<AppHarness> start(WidgetTester tester, FakeSharedSets api, {bool signedIn = false}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await AppHarness.start(
    tester,
    welcomeSeen: true,
    seed: (a) => a.addAccount('a@x.co', 'Passw0rd1', name: 'Anna'),
    overrides: [sharedSetsApiProvider.overrideWithValue(api), clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))],
  );
  if (signedIn) {
    await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
    expect(app.container.read(authRepositoryProvider).state, isA<SignedIn>());
  }
  return app;
}

Future<void> openShared(WidgetTester tester) async {
  await tapText(tester, '我');
  await tapText(tester, '裝備與範本');
  await tapText(tester, '雲端裝備組合');
  await settle(tester);
}

void main() {
  testWidgets('the cloud page lists public sets and the ones I shared, and search narrows the list', (tester) async {
    final api = FakeSharedSets();
    final app = await start(tester, api);
    await openShared(tester);
    expect(find.byKey(const ValueKey('shared-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('shared-k1')), findsOneWidget);
    expect(find.textContaining('需要 Key'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('shared-search')), '嘉明');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.byKey(const ValueKey('shared-p1')), findsNothing);
    expect(find.byKey(const ValueKey('shared-k1')), findsOneWidget);

    await tapText(tester, '我分享的');
    expect(find.byKey(const ValueKey('shared-m1')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('offline, the list says so and offers a retry', (tester) async {
    final api = FakeSharedSets()..offline = true;
    final app = await start(tester, api);
    await openShared(tester);
    expect(find.textContaining('目前無法連線'), findsWidgets);
    api.offline = false;
    await tester.tap(find.text('重試').first);
    await settle(tester);
    expect(find.byKey(const ValueKey('shared-p1')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a public set opens and can be saved as a template or added to a trip', (tester) async {
    final api = FakeSharedSets();
    final app = await start(tester, api);
    final trip = await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '我的行程', start: DateTime(2026, 5, 10), end: DateTime(2026, 5, 11)));
    await settle(tester);
    await openShared(tester);
    await tester.tap(find.byKey(const ValueKey('shared-p1')));
    await settle(tester);
    expect(find.text('睡袋'), findsOneWidget);
    expect(find.textContaining('爐頭'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shared-save')));
    await settleUntil(tester, find.textContaining('已存成我的範本'));
    final templates = await real(tester, () => app.db.select(app.db.templates).get());
    expect(templates.single.title, '百岳輕量化');
    expect(decodeSetItems(templates.single.items).length, 3);

    await tester.tap(find.byKey(const ValueKey('shared-add')));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('add-trip-$trip')));
    await settleUntil(tester, find.textContaining('已加入'));
    expect((await real(tester, () => app.db.select(app.db.gearItems).get())).map((g) => g.name), unorderedEquals(['睡袋', '爐頭']));
    await app.dispose(tester);
  });

  testWidgets('a protected set asks for the Key, asks again when it is wrong, and then opens', (tester) async {
    final api = FakeSharedSets();
    final app = await start(tester, api);
    await openShared(tester);
    await tester.tap(find.byKey(const ValueKey('shared-k1')));
    await settle(tester);
    expect(find.text('這份組合需要 Key'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'zzzz');
    await tapText(tester, '開啟');
    expect(find.text('Key 不正確'), findsOneWidget, reason: 'asked again, with the reason');
    await tester.enterText(find.byType(TextField).last, 'abcd');
    await tapText(tester, '開啟');
    expect(find.text('睡袋'), findsOneWidget);
    expect(api.keysTried, [null, 'zzzz', 'abcd']);
    await app.dispose(tester);
  });

  testWidgets('my own set can be taken back from the cloud', (tester) async {
    final api = FakeSharedSets();
    final app = await start(tester, api, signedIn: true);
    await openShared(tester);
    await tapText(tester, '我分享的');
    await tester.tap(find.byKey(const ValueKey('shared-m1')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('shared-delete')));
    await settle(tester);
    await tapText(tester, '取消分享');
    expect(api.deleted, ['m1']);
    await app.dispose(tester);
  });

  group('sharing a template', () {
    Future<void> openTemplate(WidgetTester tester, AppHarness app) async {
      await act(tester, () => app.container.read(templateRepositoryProvider).create(title: '夏季兩天', items: items));
      await settle(tester);
      await tapText(tester, '我');
      await tapText(tester, '裝備與範本');
      await tapText(tester, '我的範本');
      await tapText(tester, '夏季兩天');
      await tester.tap(find.byKey(const ValueKey('template-share')));
      await settle(tester);
    }

    testWidgets('a guest is asked to sign in first', (tester) async {
      final api = FakeSharedSets();
      final app = await start(tester, api);
      await openTemplate(tester, app);
      expect(find.textContaining('登入後才能分享'), findsOneWidget);
      expect(api.created, isEmpty);
      await app.dispose(tester);
    });

    testWidgets('a signed-in person shares publicly, and a protected set needs a valid Key', (tester) async {
      final api = FakeSharedSets();
      final app = await start(tester, api, signedIn: true);
      await openTemplate(tester, app);
      expect(find.byKey(const ValueKey('share-visibility')), findsOneWidget);
      await tapText(tester, '需要 Key');
      await tester.tap(find.byKey(const ValueKey('share-confirm')));
      await settle(tester);
      expect(find.textContaining('Key 要 4 到 12'), findsOneWidget);
      expect(api.created, isEmpty, reason: 'nothing is sent with an invalid Key');

      await tester.enterText(find.widgetWithText(TextField, 'Key（4 到 12 個英數字）'), 'abcd');
      await tester.tap(find.byKey(const ValueKey('share-confirm')));
      await settleUntil(tester, find.textContaining('已分享'));
      expect(api.created.single, (title: '夏季兩天', visibility: SharedVisibility.protected, key: 'abcd', count: 3));
      expect(find.textContaining('Key：abcd'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
