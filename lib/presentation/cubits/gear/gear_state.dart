import 'package:equatable/equatable.dart';
import '../../../data/models/gear_item.dart';
import '../../../core/constants.dart';

abstract class GearState extends Equatable {
  const GearState();

  @override
  List<Object?> get props => [];
}

class GearInitial extends GearState {
  const GearInitial();
}

class GearLoading extends GearState {
  const GearLoading();
}

class GearLoaded extends GearState {
  final List<GearItem> items;
  final String? selectedCategory;
  final String searchQuery;
  final bool showUncheckedOnly;

  /// 建構子
  ///
  /// [items] 裝備列表
  /// [selectedCategory] 目前篩選分類
  /// [searchQuery] 搜尋關鍵字
  /// [showUncheckedOnly] 是否僅顯示未打包項目
  const GearLoaded({required this.items, this.selectedCategory, this.searchQuery = '', this.showUncheckedOnly = false});

  /// CopyWith method for updating state
  ///
  /// [items] 更新裝備列表
  /// [selectedCategory] 更新分類
  /// [clearCategory] 是否清除分類
  /// [searchQuery] 更新搜尋關鍵字
  /// [showUncheckedOnly] 更新過濾狀態
  GearLoaded copyWith({
    List<GearItem>? items,
    String? selectedCategory,
    // Allow passing null to clear category
    bool clearCategory = false,
    String? searchQuery,
    bool? showUncheckedOnly,
  }) {
    return GearLoaded(
      items: items ?? this.items,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      showUncheckedOnly: showUncheckedOnly ?? this.showUncheckedOnly,
    );
  }

  /// 過濾後的裝備列表
  List<GearItem> get filteredItems {
    var result = items;

    if (selectedCategory != null) {
      result = result.where((item) => item.category == selectedCategory).toList();
    }

    if (showUncheckedOnly) {
      result = result.where((item) => !item.isChecked).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((item) => item.name.toLowerCase().contains(query)).toList();
    }

    return result;
  }

  /// 依分類分組的裝備
  Map<String, List<GearItem>> get itemsByCategory {
    final result = <String, List<GearItem>>{};
    for (final cat in GearCategory.all) {
      final filtered = filteredItems.where((item) => item.category == cat).toList();
      if (filtered.isNotEmpty) {
        result[cat] = filtered;
      }
    }
    return result;
  }

  /// 總重量 (克)
  double get totalWeight => items.fold(0, (sum, item) => sum + item.totalWeight);

  /// 總重量 (公斤)
  double get totalWeightKg => totalWeight / 1000;

  /// 已打包重量 (克)
  double get checkedWeight => items.where((i) => i.isChecked).fold(0, (sum, item) => sum + item.totalWeight);

  /// 已打包重量 (公斤)
  double get checkedWeightKg => checkedWeight / 1000;

  /// 打包進度
  double get packingProgress {
    if (items.isEmpty) return 0;
    final checked = items.where((item) => item.isChecked).length;
    return checked / items.length;
  }

  @override
  List<Object?> get props => [items, selectedCategory, searchQuery, showUncheckedOnly];
}

class GearError extends GearState {
  final String message;

  const GearError(this.message);

  @override
  List<Object?> get props => [message];
}
