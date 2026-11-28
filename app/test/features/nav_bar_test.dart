import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/app/nav_bar.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'harness.dart';

void main() {
  testWidgets('pages run behind the floating bar, and their buttons and writing box stay above it', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await AppHarness.start(tester, welcomeSeen: true);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '浮動列', start: DateTime(2030, 5, 10)));
    await settle(tester);

    double barTop() => tester.getTopLeft(find.byType(AppNavBar)).dy;
    final screen = tester.view.physicalSize.height;

    await tapText(tester, '浮動列');
    expect(tester.getBottomLeft(find.byType(NestedScrollView)).dy, screen, reason: 'a pushed page reaches the bottom too');
    expect(tester.getBottomLeft(find.byType(FloatingActionButton).hitTestable()).dy, lessThanOrEqualTo(barTop()));
    await app.dispose(tester);
  });

  testWidgets('the bar offers the five places', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true);
    await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text('我')).first);
    await settle(tester);
    expect(find.text('訪客模式'), findsOneWidget);
    await app.dispose(tester);
  });
}
