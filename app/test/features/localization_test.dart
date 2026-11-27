import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  testWidgets('built-in pickers and tooltips are in Traditional Chinese on an English phone', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final app = await AppHarness.start(tester, welcomeSeen: true);
    final context = tester.element(find.byType(NavigationBar));

    expect(Localizations.localeOf(context), const Locale('zh', 'TW'));
    final words = MaterialLocalizations.of(context);
    expect(words.okButtonLabel, '確定');
    expect(words.cancelButtonLabel, '取消');
    expect(words.backButtonTooltip, '返回');
    expect(words.licensesPageTitle, '授權');

    await tapText(tester, '建立第一個行程');
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await settle(tester);
    expect(find.textContaining('November'), findsNothing);
    expect(find.textContaining('月'), findsWidgets);
    await app.dispose(tester);
  });
}
