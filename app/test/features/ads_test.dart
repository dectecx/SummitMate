import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/ads/ads.dart';

import 'harness.dart';

void main() {
  testWidgets('the banner appears on the trips and explore lists only, and takes no space by default', (tester) async {
    const banner = Key('test-banner');
    final app = await AppHarness.start(
      tester,
      welcomeSeen: true,
      overrides: [adBannerBuilderProvider.overrideWithValue((_) => const SizedBox(key: banner, height: 50))],
    );
    expect(find.byKey(banner), findsOneWidget, reason: 'trips tab');
    await tapText(tester, '探索');
    expect(find.byKey(banner), findsOneWidget, reason: 'explore tab');
    await tapText(tester, '地圖');
    expect(find.byKey(banner), findsNothing, reason: 'no ads on the map');
    await app.dispose(tester);

    final plain = await AppHarness.start(tester, welcomeSeen: true);
    expect(find.byType(AdBannerSlot).evaluate().single.size!.height, 0, reason: 'no ad, no space');
    await plain.dispose(tester);
  });
}
