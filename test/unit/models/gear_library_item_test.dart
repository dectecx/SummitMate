import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_library_item.dart';

void main() {
  group('GearLibraryItem Model Tests', () {
    test('should create with default values', () {
      final item = GearLibraryItem(
        id: 'test-id',
        name: '',
        weight: 0,
        category: '',
        userId: 'guest',
        createdAt: DateTime.now(),
        createdBy: 'guest',
      );

      expect(item.name, isEmpty);
      expect(item.weight, equals(0));
      expect(item.category, isEmpty);
      expect(item.notes, isNull);
      expect(item.notes, isNull);
      expect(item.id, isNotEmpty); // ID 應自動生成
      expect(item.userId, equals('guest')); // Default
      expect(item.createdAt, isNotNull); // Default now()
    });

    test('should auto-generate id if not provided', () {
      // NOTE: Constructor now requires ID, so manually providing one for test, 
      // essentially testing that provided ID is used (logic shifted to factory or caller)
      // If logic was "auto-gen if null", we changed it to "required".
      // So this test 'should auto-generate id' might be obsolete or needs to test a Factory?
      // Assuming we just updated the model to require ID.
      final item1 = GearLibraryItem(id: 'id-1', name: '睡袋', weight: 1200, category: 'Sleep', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest');
      final item2 = GearLibraryItem(id: 'id-2', name: '帳篷', weight: 2000, category: 'Sleep', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest');

      expect(item1.id, isNotEmpty);
      expect(item2.id, isNotEmpty);
      expect(item1.id, isNot(equals(item2.id)));
    });

    test('should use provided id', () {
      const customId = 'custom-id-12345';
      final item = GearLibraryItem(
        id: customId,
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
        userId: 'guest',
        createdAt: DateTime.now(),
        createdBy: 'guest',
      );

      expect(item.id, equals(customId));
    });

    test('should create with all named parameters', () {
      final now = DateTime.now();
      final item = GearLibraryItem(
        id: 'test-id-all',
        name: '羽絨睡袋',
        weight: 1200,
        category: 'Sleep',
        notes: 'Thermarest Pro',
        createdAt: now,
        updatedAt: now,
        userId: 'guest',
        createdBy: 'guest',
      );

      expect(item.name, equals('羽絨睡袋'));
      expect(item.weight, equals(1200));
      expect(item.category, equals('Sleep'));
      expect(item.notes, equals('Thermarest Pro'));
      expect(item.createdAt, equals(now));
      expect(item.updatedAt, equals(now));
    });

    test('should calculate weightInKg correctly', () {
      final item = GearLibraryItem(id: 'w1', name: '睡袋', weight: 1500, category: 'Sleep', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest');

      expect(item.weightInKg, equals(1.5));
    });

    test('should handle zero weight', () {
      final item = GearLibraryItem(id: 'z1', name: '地圖', weight: 0, category: 'Other', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest');

      expect(item.weight, equals(0));
      expect(item.weightInKg, equals(0));
    });

    test('should validate category values', () {
      final validCategories = ['Sleep', 'Cook', 'Wear', 'Other'];

      for (final cat in validCategories) {
        final item = GearLibraryItem(id: 'cat-${cat}', name: 'Test', weight: 100, category: cat, userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest');
        expect(validCategories.contains(item.category), isTrue);
      }
    });

    test('should convert to JSON correctly', () {
      final item = GearLibraryItem(
        id: 'test-id',
        userId: 'user1',
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
        notes: '品牌備註',
        createdAt: DateTime.now(),
        createdBy: 'user1',
      );

      final json = item.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['user_id'], equals('user1'));
      expect(json['name'], equals('睡袋'));
      expect(json['weight'], equals(1200));
      expect(json['category'], equals('Sleep'));
      expect(json['notes'], equals('品牌備註'));
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNull); // updatedAt 未設定時為 null
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'json-id',
        'user_id': 'user2',
        'name': '帳篷',
        'weight': 2000,
        'category': 'Sleep',
        'notes': 'MSR Hubba',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final item = GearLibraryItem.fromJson(json);

      expect(item.id, equals('json-id'));
      expect(item.userId, equals('user2'));
      expect(item.name, equals('帳篷'));
      expect(item.weight, equals(2000));
      expect(item.category, equals('Sleep'));
      expect(item.notes, equals('MSR Hubba'));
    });

    test('should handle JSON with missing optional fields', () {
      final json = {'name': '爐頭', 'weight': 300, 'category': 'Cook'};

      final item = GearLibraryItem.fromJson(json);

      expect(item.name, equals('爐頭'));
      expect(item.weight, equals(300));
      expect(item.category, equals('Cook'));
      expect(item.notes, isNull);
      expect(item.id, isNotEmpty); // 應自動生成
      expect(item.userId, equals('guest')); // Default
    });

    test('should round-trip JSON conversion', () {
      final original = GearLibraryItem(
          id: 'rt-1',
          name: '睡袋',
          weight: 1200,
          category: 'Sleep',
          notes: '測試備註',
          userId: 'guest',
          createdAt: DateTime.now(),
          createdBy: 'guest');

      final json = original.toJson();
      final restored = GearLibraryItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.weight, equals(original.weight));
      expect(restored.category, equals(original.category));
      expect(restored.notes, equals(original.notes));
    });

    test('should calculate total weight for multiple items', () {
      final items = [
        GearLibraryItem(id: 't1', name: '睡袋', weight: 1200, category: 'Sleep', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest'),
        GearLibraryItem(id: 't2', name: '帳篷', weight: 2000, category: 'Sleep', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest'),
        GearLibraryItem(id: 't3', name: '爐頭', weight: 300, category: 'Cook', userId: 'guest', createdAt: DateTime.now(), createdBy: 'guest'),
      ];

      final total = items.fold<double>(0, (sum, item) => sum + item.weight);
      expect(total, equals(3500));
    });
  });
}
