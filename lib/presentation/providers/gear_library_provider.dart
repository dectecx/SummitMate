import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/gear_library_item.dart';
import '../../data/repositories/interfaces/i_gear_library_repository.dart';
import '../../services/log_service.dart';

/// 裝備庫狀態管理
///
/// 管理個人裝備庫 (GearLibraryItem) 的 CRUD 操作。
/// TripGear 透過 libraryItemId 連結到此處的項目，實現連動更新。
///
/// 【雲端備份】
/// - 私人模式，使用 owner_key 識別
/// - 上傳: 覆寫雲端 | 下載: 覆寫本地
///
/// 【未來規劃】
/// - 會員登入後改用 user_id 綁定
/// - 移除 owner_key 機制，自動識別帳號
class GearLibraryProvider extends ChangeNotifier {
  final IGearLibraryRepository _repository;

  List<GearLibraryItem> _items = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  GearLibraryProvider({IGearLibraryRepository? repository})
    : _repository = repository ?? getIt<IGearLibraryRepository>() {
    LogService.info('GearLibraryProvider 初始化', source: 'GearLibrary');
    _loadItems();
  }

  // ========================================
  // Getters
  // ========================================

  /// 所有裝備庫項目
  List<GearLibraryItem> get allItems => _items;

  /// 過濾後的裝備列表
  List<GearLibraryItem> get filteredItems {
    var result = _items;

    if (_selectedCategory != null) {
      result = result.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) => item.name.toLowerCase().contains(query)).toList();
    }

    return result;
  }

  /// 依分類分組的裝備
  Map<String, List<GearLibraryItem>> get itemsByCategory {
    final result = <String, List<GearLibraryItem>>{};
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

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 錯誤訊息
  String? get error => _error;

  /// 總重量 (公克)
  double get totalWeight => _repository.getTotalWeight();

  /// 總重量 (公斤)
  double get totalWeightKg => totalWeight / 1000;

  /// 項目數量
  int get itemCount => _items.length;

  // ========================================
  // Loading
  // ========================================

  void _loadItems() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _items = _repository.getAllItems();
      LogService.debug('載入 ${_items.length} 個裝備庫項目', source: 'GearLibrary');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LogService.error('載入裝備庫失敗: $e', source: 'GearLibrary');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重新載入
  void reload() {
    LogService.debug('裝備庫重新載入', source: 'GearLibrary');
    _loadItems();
  }

  // ========================================
  // Filter / Search
  // ========================================

  /// 選擇分類過濾
  void selectCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// 設定搜尋關鍵字
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ========================================
  // CRUD Operations
  // ========================================

  /// 新增裝備到庫
  Future<GearLibraryItem> addItem({
    required String name,
    required double weight,
    required String category,
    String? notes,
  }) async {
    try {
      final item = GearLibraryItem(name: name, weight: weight, category: category, notes: notes);

      LogService.info('新增裝備庫項目: $name (${weight}g)', source: 'GearLibrary');
      await _repository.addItem(item);
      _loadItems();
      return item;
    } catch (e) {
      LogService.error('新增裝備庫項目失敗: $e', source: 'GearLibrary');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 更新裝備
  Future<void> updateItem(GearLibraryItem item) async {
    try {
      LogService.info('更新裝備庫項目: ${item.name}', source: 'GearLibrary');
      await _repository.updateItem(item);
      _loadItems();
    } catch (e) {
      LogService.error('更新裝備庫項目失敗: $e', source: 'GearLibrary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 刪除裝備
  Future<void> deleteItem(String uuid) async {
    try {
      final item = _items.firstWhere((i) => i.uuid == uuid);
      LogService.warning('刪除裝備庫項目: ${item.name}', source: 'GearLibrary');
      await _repository.deleteItem(uuid);
      _loadItems();
    } catch (e) {
      LogService.error('刪除裝備庫項目失敗: $e', source: 'GearLibrary');
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========================================
  // Lookup Methods (for linking)
  // ========================================

  /// 依 UUID 取得裝備項目
  GearLibraryItem? getById(String uuid) {
    return _repository.getById(uuid);
  }

  /// 檢查 UUID 是否存在於裝備庫
  bool containsItem(String uuid) {
    return _repository.getById(uuid) != null;
  }

  // ========================================
  // Cloud Sync (placeholder)
  // ========================================

  /// 上傳裝備庫到雲端 (覆寫)
  /// TODO: 實作 GearLibraryCloudService
  Future<void> uploadToCloud(String ownerKey) async {
    throw UnimplementedError('GearLibraryCloudService not implemented yet');
  }

  /// 從雲端下載裝備庫 (覆寫本地)
  /// TODO: 實作 GearLibraryCloudService
  Future<void> downloadFromCloud(String ownerKey) async {
    throw UnimplementedError('GearLibraryCloudService not implemented yet');
  }
}
