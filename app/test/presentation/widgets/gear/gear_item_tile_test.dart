import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/presentation/widgets/gear/gear_item_tile.dart';
import 'package:summitmate/presentation/widgets/gear/gear_mode_selector.dart';

void main() {
  group('GearItemTile Widget Test', () {
    final gearItem = GearItem(
      uuid: '1',
      name: 'Test Gear',
      weight: 100,
      category: 'Other',
      isChecked: false,
      quantity: 1,
    );

    testWidgets('View mode displays checkbox and info', (WidgetTester tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GearItemTile(
              item: gearItem,
              mode: GearListMode.view,
              onToggle: () => toggled = true,
              onTap: () {},
              onDelete: () {},
              onIncrease: () {},
              onDecrease: () {},
            ),
          ),
        ),
      );

      // Verify basic info
      expect(find.text('Test Gear'), findsOneWidget);
      expect(find.text('100g / Other'), findsOneWidget);

      // Verify Checkbox is present
      expect(find.byType(Checkbox), findsOneWidget);

      // Verify Interaction
      await tester.tap(find.byType(Checkbox));
      expect(toggled, true);
    });

    testWidgets('Edit mode displays quantity controls and delete button', (WidgetTester tester) async {
      bool increased = false;
      bool decreased = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GearItemTile(
              item: gearItem,
              mode: GearListMode.edit,
              onToggle: () {},
              onTap: () {},
              onDelete: () => deleted = true,
              onIncrease: () => increased = true,
              onDecrease: () => decreased = true,
            ),
          ),
        ),
      );

      // Verify controls
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Verify checkbox is ABSENT in edit mode
      expect(find.byType(Checkbox), findsNothing);

      // Verify interactions
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      expect(increased, true);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      expect(decreased, true);

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, true);
    });
  });
}
