import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_library_item.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_library_repository.dart';
import 'package:summitmate/presentation/providers/gear_library_provider.dart';

/// Mock GearLibraryRepository for testing
/// 實作 IGearLibraryRepository 介面以供測試使用
class MockGearLibraryRepository implements IGearLibraryRepository {
  List<GearLibraryItem> _items = [];
  bool _initCalled = false;
  bool _throwOnGetAllItems = false;

  // 設定測試資料
  void setItems(List<GearLibraryItem> items) {
    _items = List.from(items);
  }

  // 設定是否在 getAllItems 時拋出例外
  void setThrowOnGetAllItems(bool value) {
    _throwOnGetAllItems = value;
  }

  @override
  Future<void> init() async {
    _initCalled = true;
  }

  bool get initCalled => _initCalled;

  @override
  List<GearLibraryItem> getAllItems() {
    if (_throwOnGetAllItems) {
      throw Exception('Mock error: getAllItems failed');
    }
    return List.from(_items);
  }

  @override
  GearLibraryItem? getById(String uuid) {
    try {
      return _items.firstWhere((item) => item.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

  @override
  List<GearLibraryItem> getByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  @override
  Future<void> addItem(GearLibraryItem item) async {
    _items.add(item);
  }

  @override
  Future<void> updateItem(GearLibraryItem item) async {
    final index = _items.indexWhere((i) => i.uuid == item.uuid);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> deleteItem(String uuid) async {
    _items.removeWhere((item) => item.uuid == uuid);
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  @override
  Future<void> importItems(List<GearLibraryItem> items) async {
    _items = List.from(items);
  }

  @override
  int get itemCount => _items.length;

  @override
  double getTotalWeight() {
    return _items.fold(0, (sum, item) => sum + item.weight);
  }

  @override
  Map<String, double> getWeightByCategory() {
    final result = <String, double>{};
    for (final item in _items) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }
}

void main() {
  group('GearLibraryProvider Tests', () {
    late MockGearLibraryRepository mockRepo;
    late GearLibraryProvider provider;

    setUp(() {
      mockRepo = MockGearLibraryRepository();
    });

    tearDown(() {
      provider.dispose();
    });

    test('初始化時應載入裝備列表', () async {
      mockRepo.setItems([
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero); // 等待同步操作完成

      expect(provider.allItems.length, equals(2));
      expect(provider.isLoading, isFalse);
    });

    test('filteredItems 初始狀態返回所有項目', () async {
      mockRepo.setItems([GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep')]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      expect(provider.filteredItems.length, equals(1));
    });

    test('filteredItems 應根據分類過濾', () async {
      mockRepo.setItems([
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '帳篷', weight: 2000, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      provider.selectCategory('Sleep');
      expect(provider.filteredItems.length, equals(2));

      provider.selectCategory('Cook');
      expect(provider.filteredItems.length, equals(1));

      provider.selectCategory(null); // 清除過濾
      expect(provider.filteredItems.length, equals(3));
    });

    test('filteredItems 應根據搜尋關鍵字過濾', () async {
      mockRepo.setItems([
        GearLibraryItem(name: '羽絨睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '化纖睡袋', weight: 1500, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      provider.setSearchQuery('睡袋');
      expect(provider.filteredItems.length, equals(2));

      provider.setSearchQuery('羽絨');
      expect(provider.filteredItems.length, equals(1));

      provider.setSearchQuery(''); // 清除搜尋
      expect(provider.filteredItems.length, equals(3));
    });

    test('itemsByCategory 應依分類分組', () async {
      mockRepo.setItems([
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '帳篷', weight: 2000, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      final grouped = provider.itemsByCategory;
      expect(grouped.keys.length, equals(2));
      expect(grouped['Sleep']?.length, equals(2));
      expect(grouped['Cook']?.length, equals(1));
    });

    test('addItem 應新增項目並更新列表', () async {
      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      await provider.addItem(name: '睡袋', weight: 1200, category: 'Sleep', notes: '品牌備註');

      expect(provider.allItems.length, equals(1));
      expect(provider.allItems.first.name, equals('睡袋'));
      expect(provider.allItems.first.notes, equals('品牌備註'));
    });

    test('deleteItem 應刪除項目並更新列表', () async {
      final item = GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep');
      mockRepo.setItems([item]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);
      expect(provider.allItems.length, equals(1));

      await provider.deleteItem(item.uuid);
      expect(provider.allItems.length, equals(0));
    });

    test('totalWeight 應計算正確的總重量', () async {
      mockRepo.setItems([
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      expect(provider.totalWeight, equals(1500));
      expect(provider.totalWeightKg, equals(1.5));
    });

    test('itemCount 應返回正確數量', () async {
      mockRepo.setItems([
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      expect(provider.itemCount, equals(2));
    });

    test('getById 應找到正確項目', () async {
      final item = GearLibraryItem(uuid: 'test-uuid-123', name: '睡袋', weight: 1200, category: 'Sleep');
      mockRepo.setItems([item]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      final found = provider.getById('test-uuid-123');
      expect(found, isNotNull);
      expect(found!.name, equals('睡袋'));

      final notFound = provider.getById('non-existent');
      expect(notFound, isNull);
    });

    test('containsItem 判斷項目是否存在', () async {
      final item = GearLibraryItem(uuid: 'test-uuid-456', name: '爐頭', weight: 300, category: 'Cook');
      mockRepo.setItems([item]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      expect(provider.containsItem('test-uuid-456'), isTrue);
      expect(provider.containsItem('non-existent'), isFalse);
    });

    test('error handling: 載入失敗時設定 error', () async {
      mockRepo.setThrowOnGetAllItems(true);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('reload 應重新載入資料', () async {
      mockRepo.setItems([GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep')]);

      provider = GearLibraryProvider(repository: mockRepo);
      await Future.delayed(Duration.zero);
      expect(provider.allItems.length, equals(1));

      // 新增資料後 reload
      mockRepo.setItems([
        GearLibraryItem(name: '睡袋', weight: 1200, category: 'Sleep'),
        GearLibraryItem(name: '爐頭', weight: 300, category: 'Cook'),
      ]);

      provider.reload();
      await Future.delayed(Duration.zero);
      expect(provider.allItems.length, equals(2));
    });
  });
}
