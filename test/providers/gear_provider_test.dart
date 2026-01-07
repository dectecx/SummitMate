import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';
import 'package:summitmate/presentation/providers/gear_provider.dart';

/// Mock GearRepository for testing
/// 實作 IGearRepository 介面以供測試使用
class MockGearRepository implements IGearRepository {
  List<GearItem> _items = [];
  bool _initCalled = false;
  bool _throwOnGetAllItems = false;

  // 設定測試資料
  void setItems(List<GearItem> items) {
    _items = items;
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
  List<GearItem> getAllItems() {
    if (_throwOnGetAllItems) {
      throw Exception('Mock error: getAllItems failed');
    }
    return List.from(_items);
  }

  @override
  List<GearItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  @override
  List<GearItem> getUncheckedItems() {
    return _items.where((item) => !item.isChecked).toList();
  }

  @override
  Future<int> addItem(GearItem item) async {
    _items.add(item);
    return _items.length - 1;
  }

  @override
  Future<void> updateItem(GearItem item) async {
    final index = _items.indexWhere((i) => i.name == item.name);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> deleteItem(dynamic key) async {
    _items.removeWhere((item) => item.key == key);
  }

  @override
  Future<void> toggleChecked(dynamic key) async {
    // Not implemented for mock
  }

  @override
  double getTotalWeight() {
    return _items.fold(0.0, (sum, item) => sum + item.weight);
  }

  @override
  double getCheckedWeight() {
    return _items.where((item) => item.isChecked).fold(0.0, (sum, item) => sum + item.weight);
  }

  @override
  Map<String, double> getWeightByCategory() {
    final result = <String, double>{};
    for (final item in _items) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }

  @override
  Stream<BoxEvent> watchAllItems() {
    return const Stream.empty();
  }

  @override
  Future<void> resetAllChecked() async {
    for (final item in _items) {
      item.isChecked = false;
    }
  }

  @override
  Future<void> updateItemsOrder(List<GearItem> items) async {
    _items = items;
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  // 這些方法是 GearRepository 內部使用的，需要 stub
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 建立測試用 GearItem
GearItem createTestGearItem({
  required String name,
  double weight = 100.0,
  String category = '衣物',
  bool isChecked = false,
  int? orderIndex,
  String tripId = 'test_trip',
}) {
  return GearItem(name: name, weight: weight, category: category, isChecked: isChecked, orderIndex: orderIndex, tripId: tripId);
}

void main() {
  group('GearProvider Unit Tests', () {
    late MockGearRepository mockRepository;
    late GearProvider provider;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockRepository = MockGearRepository();
      // 使用建構子注入 mock repository
      provider = GearProvider(repository: mockRepository);
      provider.setTripId('test_trip');
      provider.reload(); // Manually load since setTripId uses postFrameCallback
    });

    group('filteredItems', () {
      test('初始狀態返回空列表', () {
        expect(provider.filteredItems, isEmpty);
      });

      test('設定 items 後返回全部項目', () {
        mockRepository.setItems([createTestGearItem(name: '外套'), createTestGearItem(name: '背包')]);
        provider.reload();

        expect(provider.filteredItems.length, 2);
      });

      test('selectCategory 會過濾項目', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', category: '衣物'),
          createTestGearItem(name: '帳篷', category: '營地裝備'),
          createTestGearItem(name: '雨衣', category: '衣物'),
        ]);
        provider.reload();

        provider.selectCategory('衣物');

        expect(provider.filteredItems.length, 2);
        expect(provider.filteredItems.every((item) => item.category == '衣物'), true);
      });

      test('selectCategory(null) 顯示全部', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', category: '衣物'),
          createTestGearItem(name: '帳篷', category: '營地裝備'),
        ]);
        provider.reload();

        provider.selectCategory('衣物');
        expect(provider.filteredItems.length, 1);

        provider.selectCategory(null);
        expect(provider.filteredItems.length, 2);
      });

      test('setSearchQuery 會過濾項目', () {
        mockRepository.setItems([
          createTestGearItem(name: '防風外套'),
          createTestGearItem(name: '羽絨外套'),
          createTestGearItem(name: '背包'),
        ]);
        provider.reload();

        provider.setSearchQuery('外套');

        expect(provider.filteredItems.length, 2);
      });

      test('setSearchQuery 不分大小寫', () {
        mockRepository.setItems([
          createTestGearItem(name: 'Jacket'),
          createTestGearItem(name: 'jacket'),
          createTestGearItem(name: 'JACKET'),
        ]);
        provider.reload();

        provider.setSearchQuery('jacket');

        expect(provider.filteredItems.length, 3);
      });

      test('toggleShowUncheckedOnly 只顯示未打包', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', isChecked: true),
          createTestGearItem(name: '雨衣', isChecked: false),
          createTestGearItem(name: '手套', isChecked: false),
        ]);
        provider.reload();

        provider.toggleShowUncheckedOnly();

        expect(provider.filteredItems.length, 2);
        expect(provider.filteredItems.every((item) => !item.isChecked), true);
      });

      test('多重篩選條件可組合', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', category: '衣物', isChecked: false),
          createTestGearItem(name: '雨衣', category: '衣物', isChecked: true),
          createTestGearItem(name: '外帳', category: '營地裝備', isChecked: false),
        ]);
        provider.reload();

        provider.selectCategory('衣物');
        provider.toggleShowUncheckedOnly();

        expect(provider.filteredItems.length, 1);
        expect(provider.filteredItems.first.name, '外套');
      });
    });

    group('packingProgress', () {
      test('空列表返回 0', () {
        expect(provider.packingProgress, 0.0);
      });

      test('全部未打包返回 0', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', isChecked: false),
          createTestGearItem(name: '雨衣', isChecked: false),
        ]);
        provider.reload();

        expect(provider.packingProgress, 0.0);
      });

      test('全部已打包返回 1', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', isChecked: true),
          createTestGearItem(name: '雨衣', isChecked: true),
        ]);
        provider.reload();

        expect(provider.packingProgress, 1.0);
      });

      test('部分打包返回正確比例', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', isChecked: true),
          createTestGearItem(name: '雨衣', isChecked: false),
          createTestGearItem(name: '帳篷', isChecked: false),
          createTestGearItem(name: '睡袋', isChecked: true),
        ]);
        provider.reload();

        expect(provider.packingProgress, 0.5); // 2/4
      });
    });

    group('weight calculations', () {
      test('totalWeight 從 repository 取得', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', weight: 500),
          createTestGearItem(name: '雨衣', weight: 200),
        ]);

        expect(provider.totalWeight, 700.0);
      });

      test('totalWeightKg 正確轉換', () {
        mockRepository.setItems([createTestGearItem(name: '外套', weight: 1500)]);

        expect(provider.totalWeightKg, 1.5);
      });

      test('checkedWeight 只計算已打包項目', () {
        mockRepository.setItems([
          createTestGearItem(name: '外套', weight: 500, isChecked: true),
          createTestGearItem(name: '雨衣', weight: 200, isChecked: false),
        ]);

        expect(provider.checkedWeight, 500.0);
      });
    });

    group('notifyListeners', () {
      test('selectCategory 會通知監聽者', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.selectCategory('衣物');

        expect(notifyCount, 1);
      });

      test('setSearchQuery 會通知監聽者', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setSearchQuery('外套');

        expect(notifyCount, 1);
      });

      test('toggleShowUncheckedOnly 會通知監聽者', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.toggleShowUncheckedOnly();

        expect(notifyCount, 1);
      });
    });

    group('error handling', () {
      test('reload 失敗時設定 error', () {
        mockRepository.setThrowOnGetAllItems(true);

        provider.reload();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Mock error'));
      });
    });
  });
}
