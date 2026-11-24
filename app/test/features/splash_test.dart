import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/shared/brand/splash_overlay.dart';

void main() {
  testWidgets('the opening animation covers the app, then fades away by itself', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashOverlay(child: Text('首頁'))));
    expect(find.byKey(const ValueKey('splash')), findsOneWidget);
    expect(find.text('SummitMate'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('splash')), findsNothing);
    expect(find.text('首頁'), findsOneWidget);
  });

  testWidgets('a tap skips the animation, and it can be turned off', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashOverlay(child: Text('首頁'))));
    await tester.tap(find.byKey(const ValueKey('splash')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('splash')), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SplashOverlay(enabled: false, child: Text('首頁2'))));
    expect(find.byKey(const ValueKey('splash')), findsNothing);
  });
}
