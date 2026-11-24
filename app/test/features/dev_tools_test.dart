import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  testWidgets('the developer panel adds a random trip with itinerary, gear and meals, then more gear', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await AppHarness.start(tester, welcomeSeen: true, devTools: true);

    await tester.tap(find.byKey(const ValueKey('dev-tools-button')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('dev-random-trip')));
    await settle(tester);
    expect(find.textContaining('已新增行程'), findsOneWidget);

    final trips = await real(tester, () => app.db.select(app.db.trips).get());
    expect(trips, hasLength(1));
    final tripId = trips.single.id;
    expect(await real(tester, () => app.db.select(app.db.itineraryItems).get()), isNotEmpty);
    final gearBefore = (await real(tester, () => app.db.select(app.db.gearItems).get())).length;
    expect(gearBefore, greaterThanOrEqualTo(4));
    expect(await real(tester, () => app.db.select(app.db.mealItems).get()), isNotEmpty);

    await tester.tap(find.byKey(const ValueKey('dev-random-gear')));
    await settle(tester);
    expect((await real(tester, () => app.db.select(app.db.gearItems).get())).length, greaterThan(gearBefore));
    expect(trips.single.id, tripId);
    await app.dispose(tester);
  });
}
