import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/gear_item.dart';
import '../../data/repositories/gear_repository.dart';
import '../../services/log_service.dart';

/// 裝備狀態管理
class GearProvider extends ChangeNotifier {
  final GearRepository _repository;

  List<GearItem> _items = [];
  String? _selectedCategory; // null 表示顯示全部
  bool _showUncheckedOnly = false;
  bool _isLoading = true;
  String? _error;

  GearProvider() : _repository = getIt<GearRepository>() {
    LogService.info('GearProvider 初始化', source: 'Gear');
    _loadItems();
  }

  /// 所有裝備
  List<GearItem> get allItems => _items;

  /// 過濾後的裝備列表
  List<GearItem> get filteredItems {
    var result = _items;

    if (_selectedCategory != null) {
      result = result.where((item) => item.category == _selectedCategory).toList();
    }

    if (_showUncheckedOnly) {
      result = result.where((item) => !item.isChecked).toList();
    }

    return result;
  }

  /// 依分類分組的裝備
  Map<String, List<GearItem>> get itemsByCategory {
    final result = <String, List<GearItem>>{};
    for (final cat in GearCategory.all) {
      final items = filteredItems.where((item) => item.category == cat).toList();
      if (items.isNotEmpty) {
        result[cat] = items;
      }
    }
    return result;
  }

  /// 當前選擇的分類 (null 表示全部)
  String? get selectedCategory => _selectedCategory;

  /// 是否只顯示未打包
  bool get showUncheckedOnly => _showUncheckedOnly;

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 錯誤訊息
  String? get error => _error;

  /// 總重量 (克)
  double get totalWeight => _repository.getTotalWeight();

  /// 總重量 (公斤)
  double get totalWeightKg => totalWeight / 1000;

  /// 已打包重量 (克)
  double get checkedWeight => _repository.getCheckedWeight();

  /// 已打包重量 (公斤)
  double get checkedWeightKg => checkedWeight / 1000;

  /// 打包進度
  double get packingProgress {
    if (_items.isEmpty) return 0;
    final checked = _items.where((item) => item.isChecked).length;
    return checked / _items.length;
  }

  /// 依分類統計重量
  Map<String, double> get weightByCategory => _repository.getWeightByCategory();

  /// 載入裝備
  void _loadItems() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _items = _repository.getAllItems();
      LogService.debug('載入 ${_items.length} 個裝備', source: 'Gear');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LogService.error('載入裝備失敗: $e', source: 'Gear');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 選擇分類過濾
  void selectCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// 切換只顯示未打包
  void toggleShowUncheckedOnly() {
    _showUncheckedOnly = !_showUncheckedOnly;
    notifyListeners();
  }

  /// 新增裝備
  Future<void> addItem({required String name, required double weight, required String category}) async {
    try {
      final item = GearItem(name: name, weight: weight, category: category, isChecked: false);

      LogService.info('新增裝備: $name (${weight}g)', source: 'Gear');
      await _repository.addItem(item);
      _loadItems();
    } catch (e) {
      LogService.error('新增裝備失敗: $e', source: 'Gear');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新裝備
  Future<void> updateItem(GearItem item) async {
    try {
      LogService.info('更新裝備: ${item.name}', source: 'Gear');
      await _repository.updateItem(item);
      _loadItems();
    } catch (e) {
      LogService.error('更新裝備失敗: $e', source: 'Gear');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 刪除裝備
  Future<void> deleteItem(dynamic key) async {
    try {
      final item = _items.firstWhere((i) => i.key == key);
      LogService.warning('刪除裝備: ${item.name}', source: 'Gear');
      await _repository.deleteItem(key);
      _loadItems();
    } catch (e) {
      LogService.error('刪除裝備失敗: $e', source: 'Gear');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 切換打包狀態
  Future<void> toggleChecked(dynamic key) async {
    try {
      final item = _items.firstWhere((i) => i.key == key);
      LogService.debug('切換打包: ${item.name} -> ${!item.isChecked}', source: 'Gear');
      await _repository.toggleChecked(key);
      _loadItems();
    } catch (e) {
      LogService.error('切換打包失敗: $e', source: 'Gear');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重置所有打包狀態
  Future<void> resetAllChecked() async {
    try {
      LogService.warning('重置所有打包狀態', source: 'Gear');
      await _repository.resetAllChecked();
      _loadItems();
    } catch (e) {
      LogService.error('重置打包失敗: $e', source: 'Gear');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重新排序裝備
  Future<void> reorderItem(int oldIndex, int newIndex, {String? category}) async {
    try {
      // 1. 取得操作目標列表 (全列表或分類列表)
      final targetList = category == null ? _items : _items.where((item) => item.category == category).toList();

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // 2. 在目標列表中移動 item
      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      // 3. 如果是特定分類，需將新順序套回全列表 (保持其他分類位置不變)
      final List<GearItem> finalSortedList;
      if (category == null) {
        finalSortedList = targetList;
      } else {
        finalSortedList = List<GearItem>.from(_items);
        int targetIndex = 0;
        for (int i = 0; i < finalSortedList.length; i++) {
          if (finalSortedList[i].category == category) {
            finalSortedList[i] = targetList[targetIndex++];
          }
        }
      }

      // 4. 更新資料庫內的 orderIndex
      await _repository.updateItemsOrder(finalSortedList);

      // 5. 重新載入
      _loadItems();
    } catch (e, stackTrace) {
      LogService.error('排序失敗: $e', source: 'Gear', stackTrace: stackTrace);
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重新載入
  void reload() {
    LogService.debug('裝備重新載入', source: 'Gear');
    _loadItems();
  }
}
