import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/account/help_page.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'harness.dart';

void main() {
  testWidgets('the help page lists the questions and opens an answer', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true);
    await tapText(tester, '我');
    await tapText(tester, '使用說明');
    for (final t in HelpPage.topics) {
      expect(find.byKey(ValueKey('help-${t.question}')), findsOneWidget);
    }
    await tester.tap(find.byKey(ValueKey('help-${HelpPage.topics[1].question}')));
    await settle(tester);
    expect(find.textContaining('出發前先下載'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('with no trips the list offers a GPX import as well as the first trip and the sample', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true);
    expect(find.text('建立第一個行程'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-import-gpx')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('the gear tip shows once with some gear, and stays away after it was dismissed', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))]);
    await tester.tap(find.text('用範例行程試試看'));
    await settle(tester);
    await tapText(tester, '裝備');
    expect(find.textContaining('勾選代表已打包'), findsOneWidget);
    await tester.tap(find.byTooltip('知道了'));
    await settle(tester);
    expect(find.textContaining('勾選代表已打包'), findsNothing);
    await tapText(tester, '餐食');
    await tapText(tester, '裝備');
    expect(find.textContaining('勾選代表已打包'), findsNothing, reason: 'dismissed tips do not come back');
    await app.dispose(tester);
  });
}
