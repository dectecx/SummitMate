import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'events_fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('the bookmark saves an event offline-first and 我的收藏 → 揪團 lists it', (tester) async {
    final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日'), ev('e2', '雪山東峰')]);
    final app = await startEvents(tester, api, signedIn: true);
    await openEvents(tester);
    await openEvent(tester, 'e1');

    await tester.tap(find.byKey(const ValueKey('fav-event-e1')));
    await settle(tester);
    final rows = await real(tester, () => app.db.select(app.db.favorites).get());
    expect(rows.map((r) => [r.kind, r.targetId]), [['group_event', 'e1']]);
    expect((await real(tester, () => app.db.select(app.db.outbox).get())).length, 1);

    await tester.pageBack();
    await settle(tester);
    await tapText(tester, '我');
    await tapText(tester, '我的收藏');
    await tester.tap(find.widgetWithText(Tab, '揪團'));
    await settle(tester);
    await settleUntil(tester, find.byKey(const ValueKey('event-e1')));
    expect(find.text('嘉明湖三日'), findsOneWidget);
    expect(find.text('雪山東峰'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fav-event-e1'))); // remove it
    await settle(tester);
    expect(find.textContaining('還沒有收藏的揪團'), findsOneWidget);
    await app.dispose(tester);
  });
}
