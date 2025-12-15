import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/gear_item.dart';
import '../../data/repositories/gear_repository.dart';

/// 裝備狀態管理
class GearProvider extends ChangeNotifier {
  final GearRepository _repository;

  List<GearItem> _items = [];
  String? _selectedCategory; // null 表示顯示全部
  bool _showUncheckedOnly = false;
  bool _isLoading = true;
  String? _error;

  GearProvider() : _repository = getIt<GearRepository>() {
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
  double get totalWeight => _items.fold<double>(0.0, (sum, item) => sum + item.weight);

  /// 總重量 (公斤)
  double get totalWeightKg => totalWeight / 1000;

  /// 已打包重量 (克)
  double get checkedWeight => _items
      .where((item) => item.isChecked)
      .fold<double>(0.0, (sum, item) => sum + item.weight);

  /// 已打包重量 (公斤)
  double get checkedWeightKg => checkedWeight / 1000;

  /// 打包進度
  double get packingProgress {
    if (_items.isEmpty) return 0;
    final checked = _items.where((item) => item.isChecked).length;
    return checked / _items.length;
  }

  /// 依分類統計重量
  Map<String, double> get weightByCategory {
    final result = <String, double>{};
    for (final item in _items) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }

  /// 載入裝備
  Future<void> _loadItems() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _items = await _repository.getAllItems();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
  Future<void> addItem({
    required String name,
    required double weight,
    required String category,
  }) async {
    try {
      final item = GearItem()
        ..name = name
        ..weight = weight
        ..category = category
        ..isChecked = false;

      await _repository.addItem(item);
      await _loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新裝備
  Future<void> updateItem(GearItem item) async {
    try {
      await _repository.updateItem(item);
      await _loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 刪除裝備
  Future<void> deleteItem(int id) async {
    try {
      await _repository.deleteItem(id);
      await _loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 切換打包狀態
  Future<void> toggleChecked(int id) async {
    try {
      await _repository.toggleChecked(id);
      await _loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重置所有打包狀態
  Future<void> resetAllChecked() async {
    try {
      await _repository.resetAllChecked();
      await _loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重新載入
  Future<void> reload() async {
    await _loadItems();
  }
}
