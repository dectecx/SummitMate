import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_library_item.dart';

void main() {
  group('GearLibraryItem Model Tests', () {
    test('should create with default values', () {
      final item = GearLibraryItem(name: '', weight: 0, category: '');

      expect(item.name, isEmpty);
      expect(item.weight, equals(0));
      expect(item.category, isEmpty);
      expect(item.notes, isNull);
      expect(item.uuid, isNotEmpty); // UUID 應自動生成
    });

    test('should auto-generate uuid if not provided', () {
      final item1 = GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep');
      final item2 = GearLibraryItem(name: '帳篷', weight: 2000, category: 'Sleep');

      expect(item1.uuid, isNotEmpty);
      expect(item2.uuid, isNotEmpty);
      expect(item1.uuid, isNot(equals(item2.uuid))); // 應為不同 UUID
    });

    test('should use provided uuid', () {
      const customUuid = 'custom-uuid-12345';
      final item = GearLibraryItem(
        uuid: customUuid,
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
      );

      expect(item.uuid, equals(customUuid));
    });

    test('should create with all named parameters', () {
      final now = DateTime.now();
      final item = GearLibraryItem(
        name: '羽絨睡袋',
        weight: 1200,
        category: 'Sleep',
        notes: 'Thermarest Pro',
        createdAt: now,
        updatedAt: now,
      );

      expect(item.name, equals('羽絨睡袋'));
      expect(item.weight, equals(1200));
      expect(item.category, equals('Sleep'));
      expect(item.notes, equals('Thermarest Pro'));
      expect(item.createdAt, equals(now));
      expect(item.updatedAt, equals(now));
    });

    test('should calculate weightInKg correctly', () {
      final item = GearLibraryItem(name: '睡袋', weight: 1500, category: 'Sleep');

      expect(item.weightInKg, equals(1.5));
    });

    test('should handle zero weight', () {
      final item = GearLibraryItem(name: '地圖', weight: 0, category: 'Other');

      expect(item.weight, equals(0));
      expect(item.weightInKg, equals(0));
    });

    test('should validate category values', () {
      final validCategories = ['Sleep', 'Cook', 'Wear', 'Other'];

      for (final cat in validCategories) {
        final item = GearLibraryItem(name: 'Test', weight: 100, category: cat);
        expect(validCategories.contains(item.category), isTrue);
      }
    });

    test('should convert to JSON correctly', () {
      final item = GearLibraryItem(
        uuid: 'test-uuid',
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
        notes: '品牌備註',
      );

      final json = item.toJson();

      expect(json['uuid'], equals('test-uuid'));
      expect(json['name'], equals('睡袋'));
      expect(json['weight'], equals(1200));
      expect(json['category'], equals('Sleep'));
      expect(json['notes'], equals('品牌備註'));
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNull); // updatedAt 未設定時為 null
    });

    test('should create from JSON correctly', () {
      final json = {
        'uuid': 'json-uuid',
        'name': '帳篷',
        'weight': 2000,
        'category': 'Sleep',
        'notes': 'MSR Hubba',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final item = GearLibraryItem.fromJson(json);

      expect(item.uuid, equals('json-uuid'));
      expect(item.name, equals('帳篷'));
      expect(item.weight, equals(2000));
      expect(item.category, equals('Sleep'));
      expect(item.notes, equals('MSR Hubba'));
    });

    test('should handle JSON with missing optional fields', () {
      final json = {
        'name': '爐頭',
        'weight': 300,
        'category': 'Cook',
      };

      final item = GearLibraryItem.fromJson(json);

      expect(item.name, equals('爐頭'));
      expect(item.weight, equals(300));
      expect(item.category, equals('Cook'));
      expect(item.notes, isNull);
      expect(item.uuid, isNotEmpty); // 應自動生成
    });

    test('should round-trip JSON conversion', () {
      final original = GearLibraryItem(
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
        notes: '測試備註',
      );

      final json = original.toJson();
      final restored = GearLibraryItem.fromJson(json);

      expect(restored.uuid, equals(original.uuid));
      expect(restored.name, equals(original.name));
      expect(restored.weight, equals(original.weight));
      expect(restored.category, equals(original.category));
      expect(restored.notes, equals(original.notes));
    });

    test('should calculate total weight for multiple items', () {
      final items = [
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '帳篷', weight: 2000, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ];

      final total = items.fold<double>(0, (sum, item) => sum + item.weight);
      expect(total, equals(3500));
    });
  });
}
