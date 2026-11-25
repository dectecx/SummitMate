import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/shared/form_sheet.dart';

void main() {
  testWidgets('a form sheet ignores swiping down and tapping outside, and closes with ✕', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFormSheet<void>(context: context, builder: (_) => const SizedBox(height: 300, child: Center(child: Text('表單')))),
            child: const Text('開啟'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('開啟'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('表單'), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('表單'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    expect(find.text('表單'), findsNothing);
  });
}
