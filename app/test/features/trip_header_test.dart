import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/settings/app_settings.dart';
import 'package:summitmate/features/trips/domain/trip_art.dart';
import 'package:summitmate/features/trips/providers.dart';
import 'package:summitmate/shared/brand/art/art_view.dart';

import 'harness.dart';

void main() {
  test('a trip always gets the same cover, and ids spread over all of them', () {
    expect(coverFor('0f8c7a2e-trip', coverCount), coverFor('0f8c7a2e-trip', coverCount));
    // pinned values: changing the hash would silently give every existing trip another cover
    expect([coverFor('', 4), coverFor('a', 4), coverFor('trip-1', 4)], [1, 0, 0]);
    expect({for (var i = 0; i < 40; i++) coverFor('trip-$i', coverCount)}, hasLength(coverCount));
  });

  test('node pictures follow the name', () {
    expect(artIconFor('向陽登山口'), ArtIcon.map);
    expect(artIconFor('向陽山屋'), ArtIcon.tent);
    expect(artIconFor('黑水塘'), ArtIcon.water);
    expect(artIconFor('雪山東峰'), ArtIcon.summit);
    expect(artIconFor('集合'), isNull);
  });

  Future<AppHarness> openTrip(WidgetTester tester, {bool animations = true}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))]);
    if (!animations) {
      await act(tester, () => app.container.read(settingsStoreProvider).setBool(SettingsStore.animations, false));
    }
    final trips = app.container.read(tripRepositoryProvider);
    await act(tester, () async {
      await trips.create(name: '雪山三日', start: DateTime(2026, 5, 10), end: DateTime(2026, 5, 12));
    });
    await tapText(tester, '雪山三日');
    final id = app.container.read(tripsProvider).value!.single.id;
    await act(tester, () async {
      for (var i = 0; i < 12; i++) {
        await app.container.read(itineraryRepositoryProvider).add(id, dayIndex: 1, name: '節點$i', estMinutes: 300 + i * 30, distance: 1);
      }
    });
    return app;
  }

  double opacityOf(WidgetTester tester, Finder of) =>
      tester.widget<Opacity>(find.ancestor(of: of, matching: find.byType(Opacity)).first).opacity;

  testWidgets('the cover and card show on opening, then wash out under a pinned title and tabs', (tester) async {
    final app = await openTrip(tester);
    final card = find.byKey(const ValueKey('trip-info-card'));
    expect(find.byType(CoverArt), findsOneWidget);
    expect(opacityOf(tester, find.byType(CoverArt)), 1);
    expect(opacityOf(tester, card), 1);
    expect(find.text('3 天'), findsOneWidget);
    expect(find.text('12 km'), findsOneWidget, reason: 'distances typed on the nodes');
    expect(find.text('爬升'), findsNothing, reason: 'no track, no made-up number');

    await tester.drag(find.byType(TabBarView), const Offset(0, -600));
    await settle(tester);
    expect(opacityOf(tester, find.byType(CoverArt)), closeTo(.25, .01));
    expect(opacityOf(tester, card), 0);
    expect(tester.getTopLeft(find.byType(TabBar)).dy, lessThan(110));
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.dispose(tester);
  });

  testWidgets('another tab opens with the header already collapsed', (tester) async {
    final app = await openTrip(tester);
    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('裝備')));
    await settle(tester);
    expect(tester.getTopLeft(find.byType(TabBar)).dy, lessThan(110));
    expect(tester.takeException(), isNull);
    await app.dispose(tester);
  });

  testWidgets('with animations off the header switches looks instead of blending', (tester) async {
    final app = await openTrip(tester, animations: false);
    await tester.drag(find.byType(TabBarView), const Offset(0, -90));
    await settle(tester);
    expect(opacityOf(tester, find.byType(CoverArt)), anyOf(1, closeTo(.25, .001)));
    await app.dispose(tester);
  });

  testWidgets('the animation switch is saved', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true);
    await tapText(tester, '我');
    final toggle = find.byKey(const ValueKey('animations-switch'));
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await settle(tester);
    await tester.tap(toggle);
    await settle(tester);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(await real(tester, () => app.container.read(settingsStoreProvider).get(SettingsStore.animations)), 'false');
    await app.dispose(tester);
  });

  testWidgets('large text and the dark theme lay out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final app = await openTrip(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CoverArt), const Offset(0, -500));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await app.dispose(tester);
  });
}
