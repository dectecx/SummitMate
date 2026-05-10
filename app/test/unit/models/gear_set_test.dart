import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/domain.dart';

void main() {
  group('GearSet', () {
    test('fromJson handles actual numbers for weight and count', () {
      final json = {
        'id': 'uuid-123',
        'title': 'Test Set',
        'author': 'User',
        'totalWeight': 1500.5, // Number
        'itemCount': 10, // Number
        'visibility': 'public',
        'uploadedAt': '2025-01-01T10:00:00.000Z',
        'createdAt': '2025-01-01T10:00:00.000Z',
        'createdBy': 'User',
        'updatedAt': '2025-01-01T10:00:00.000Z',
        'updatedBy': 'User',
        'items': [],
      };

      final gearSet = GearSet.fromJson(json);

      expect(gearSet.totalWeight, 1500.5);
      expect(gearSet.itemCount, 10);
    });

    test('fromJson throws when required fields are missing', () {
      final json = {
        'id': 'uuid-123',
        // title missing
      };
      // Freezed generated fromJson will likely throw checked_yaml error or null check error
      expect(() => GearSet.fromJson(json), throwsA(anything));
    });

    test('fromJson handles meals correctly', () {
      final json = {
        'id': 'uuid-123',
        'title': 'Test Set',
        'author': 'User',
        'totalWeight': 10.0,
        'itemCount': 1,
        'visibility': 'public',
        'uploadedAt': '2025-01-01T10:00:00.000Z',
        'createdAt': '2025-01-01T10:00:00.000Z',
        'createdBy': 'User',
        'updatedAt': '2025-01-01T10:00:00.000Z',
        'updatedBy': 'User',
        'meals': [
          {
            'day': 'D1',
            'meals': {
              'breakfast': [
                {'id': 'm1', 'name': 'Bread', 'weight': 100, 'calories': 300},
              ],
            },
          },
        ],
      };

      final gearSet = GearSet.fromJson(json);
      expect(gearSet.meals, isNotNull);
      expect(gearSet.meals!.length, 1);
      expect(gearSet.meals![0].dayInfo.name, 'D1');
      expect(gearSet.meals![0].meals[MealType.breakfast]!.first.name, 'Bread');
    });

    test('toJson converts correctly', () {
      final gearSet = GearSet(
        id: 'uuid-123',
        title: 'Test Set',
        author: 'User',
        totalWeight: 1200.0,
        itemCount: 5,
        visibility: GearSetVisibility.private,
        uploadedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        createdAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        createdBy: 'User',
        updatedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        updatedBy: 'User',
        items: [const GearItem(id: 'i1', name: 'Item 1', weight: 100, category: 'Misc', tripId: 'trip1')],
      );

      final json = gearSet.toJson();

      expect(json['id'], 'uuid-123');
      expect(json['title'], 'Test Set');
      expect(json['totalWeight'], 1200.0);
      expect(json['itemCount'], 5);
      expect(json['visibility'], 'private');
      expect(json['uploadedAt'], '2025-01-01T10:00:00.000Z');
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, 1);
    });
  });
}
