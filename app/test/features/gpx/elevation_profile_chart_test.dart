import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/gpx/domain/elevation_profile.dart';
import 'package:summitmate/features/gpx/ui/elevation_profile_chart.dart';

Widget _wrap(Widget child, {double width = 400}) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: width, child: child)),
  ),
);

const _data = [ProfilePoint(0, 1000), ProfilePoint(2, 1500), ProfilePoint(5, 1200), ProfilePoint(9.5, 2100)];

void main() {
  testWidgets('renders chart with data', (tester) async {
    await tester.pumpWidget(_wrap(const ElevationProfileChart(profile: _data)));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.bySemanticsLabel('海拔剖面圖'), findsOneWidget);
    expect(find.text('沒有海拔資料'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows placeholder without data', (tester) async {
    await tester.pumpWidget(_wrap(const ElevationProfileChart(profile: [ProfilePoint(0, 1)])));
    expect(find.text('沒有海拔資料'), findsOneWidget);
    await tester.pumpWidget(_wrap(const ElevationProfileChart(profile: [])));
    expect(find.text('沒有海拔資料'), findsOneWidget);
  });

  testWidgets('does not overflow at 320 px', (tester) async {
    await tester.pumpWidget(_wrap(const ElevationProfileChart(profile: _data), width: 320));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ElevationProfileChart)).width, 320);
  });
}
