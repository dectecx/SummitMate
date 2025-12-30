import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_set.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/models/meal_item.dart';

void main() {
  group('GearSet', () {
    test('fromJson handles actual numbers for weight and count', () {
      final json = {
        'uuid': 'uuid-123',
        'title': 'Test Set',
        'author': 'User',
        'total_weight': 1500.5, // Number
        'item_count': 10, // Number
        'visibility': 'public',
        'uploaded_at': '2025-01-01T10:00:00.000Z',
        'items': [],
      };

      final gearSet = GearSet.fromJson(json);

      expect(gearSet.totalWeight, 1500.5);
      expect(gearSet.itemCount, 10);
    });

    test('fromJson handles missing or null values gracefully', () {
      final json = {
        'uuid': 'uuid-123',
        'title': 'Test Set',
        // author missing
        // total_weight missing
        // item_count missing
        // visibility missing
        // uploaded_at missing
        // items missing
      };

      final gearSet = GearSet.fromJson(json);

      expect(gearSet.author, 'Unknown');
      expect(gearSet.totalWeight, 0.0);
      expect(gearSet.itemCount, 0);
      expect(gearSet.visibility, GearSetVisibility.public); // Default
      expect(gearSet.items, null);
      expect(gearSet.meals, null);
    });

    test('fromJson handles meals correctly', () {
      final json = {
        'uuid': 'uuid-123',
        'title': 'Test Set',
        'author': 'User',
        'total_weight': 10.0,
        'item_count': 1,
        'visibility': 'public',
        'uploaded_at': '2025-01-01T10:00:00.000Z',
        'meals': [
          {
            'day': 'D1',
            'meals': {
              'breakfast': [
                {'name': 'Bread', 'weight': 100, 'calories': 300},
              ],
            },
          },
        ],
      };

      final gearSet = GearSet.fromJson(json);
      expect(gearSet.meals, isNotNull);
      expect(gearSet.meals!.length, 1);
      expect(gearSet.meals![0].day, 'D1');
      expect(gearSet.meals![0].meals[MealType.breakfast]!.first.name, 'Bread');
    });

    test('toJson converts correctly', () {
      final gearSet = GearSet(
        uuid: 'uuid-123',
        title: 'Test Set',
        author: 'User',
        totalWeight: 1200.0,
        itemCount: 5,
        visibility: GearSetVisibility.private,
        uploadedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        items: [GearItem(name: 'Item 1', weight: 100, category: 'Misc', tripId: 'trip1')],
      );

      final json = gearSet.toJson();

      expect(json['uuid'], 'uuid-123');
      expect(json['title'], 'Test Set');
      expect(json['total_weight'], 1200.0);
      expect(json['item_count'], 5);
      expect(json['visibility'], 'private');
      expect(json['uploaded_at'], '2025-01-01T10:00:00.000Z');
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, 1);
    });
  });
}
