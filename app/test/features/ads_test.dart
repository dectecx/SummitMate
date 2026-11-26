import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/ads/ads.dart';
import 'package:summitmate/features/events/providers.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'events_fakes.dart';
import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';

const _ad = Key('test-ad');

Future<AppHarness> _start(WidgetTester tester, {required bool ads}) => AppHarness.start(
  tester,
  welcomeSeen: true,
  overrides: [
    clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9)),
    eventsApiProvider.overrideWithValue(FakeEventsApi(events: [ev('e1', '嘉明湖三日'), ev('e2', '雪山東峰'), ev('e3', '合歡北峰')])),
    exploreApiProvider.overrideWithValue(
      FakeExploreApi(payloadOf([m('a', '甲山', 3000), m('b', '乙山', 2900), m('c', '丙山', 2800), m('d', '丁山', 2700)])),
    ),
    if (ads) adBannerBuilderProvider.overrideWithValue((_) => const SizedBox(key: _ad, height: 50)),
  ],
);

void main() {
  testWidgets('the ad sits inside the trips, events and explore lists only', (tester) async {
    tester.view.physicalSize = const Size(400, 2000); // tall: every list item is built
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await _start(tester, ads: true);
    expect(find.byKey(_ad), findsNothing, reason: 'an empty list carries no ad');

    final trips = app.container.read(tripRepositoryProvider);
    await act(tester, () async {
      for (var i = 0; i < 3; i++) {
        await trips.create(name: '行程$i', start: DateTime(2026, 6, 1 + i));
      }
    });
    await settle(tester);
    double top(Finder f) => tester.getTopLeft(f).dy;
    expect(find.byKey(_ad), findsOneWidget);
    expect(top(find.byKey(_ad)), greaterThan(top(find.text('行程1'))), reason: 'after the second card');
    expect(top(find.byKey(_ad)), lessThan(top(find.text('行程2'))));

    await tapText(tester, '揪團');
    await settleUntil(tester, find.text('合歡北峰'));
    expect(find.byKey(_ad), findsOneWidget);
    expect(top(find.byKey(_ad)), greaterThan(top(find.text('雪山東峰'))));
    expect(top(find.byKey(_ad)), lessThan(top(find.text('合歡北峰'))));

    await tapText(tester, '探索');
    await settleUntil(tester, find.text('丁山'));
    expect(find.byKey(_ad), findsOneWidget);
    expect(top(find.byKey(_ad)), greaterThan(top(find.text('丙山'))), reason: 'after the third mountain');
    expect(top(find.byKey(_ad)), lessThan(top(find.text('丁山'))));

    await tapText(tester, '地圖');
    expect(find.byKey(_ad), findsNothing, reason: 'no ads on the map');
    await app.dispose(tester);
  });

  testWidgets('without an ad its place takes no space', (tester) async {
    final app = await _start(tester, ads: false);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '行程', start: DateTime(2026, 6, 1)));
    await settle(tester);
    expect(tester.getSize(find.byType(AdBannerSlot)).height, 0);
    await app.dispose(tester);
  });

  testWidgets('a loaded ad is a marked card that never scales the ad, also on a narrow screen', (tester) async {
    for (final width in [320.0, 402.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: const AdCard(width: 320, height: 50, child: SizedBox.expand(key: _ad))),
            ),
          ),
        ),
      );
      expect(find.text('廣告'), findsOneWidget);
      expect(tester.getSize(find.byKey(_ad)), const Size(320, 50));
      expect(tester.takeException(), isNull);
    }
  });
}
