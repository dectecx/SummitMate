import 'package:equatable/equatable.dart';
import '../../../data/models/gear_library_item.dart';
import '../../../core/constants.dart';

abstract class GearLibraryState extends Equatable {
  const GearLibraryState();

  @override
  List<Object?> get props => [];
}

class GearLibraryInitial extends GearLibraryState {
  const GearLibraryInitial();
}

class GearLibraryLoading extends GearLibraryState {
  const GearLibraryLoading();
}

class GearLibraryLoaded extends GearLibraryState {
  final List<GearLibraryItem> items;
  final String? selectedCategory;
  final String searchQuery;

  /// 建構子
  ///
  /// [items] 裝備庫項目列表
  /// [selectedCategory] 目前選擇的分類 (null 表示全部)
  /// [searchQuery] 搜尋關鍵字
  const GearLibraryLoaded({required this.items, this.selectedCategory, this.searchQuery = ''});

  GearLibraryLoaded copyWith({
    List<GearLibraryItem>? items,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
  }) {
    return GearLibraryLoaded(
      items: items ?? this.items,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// 過濾後的裝備列表
  List<GearLibraryItem> get filteredItems {
    var result = items;

    if (selectedCategory != null) {
      result = result.where((item) => item.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((item) => item.name.toLowerCase().contains(query)).toList();
    }

    // 依最後使用時間或建立時間排序？目前 Provider 沒特別排序
    return result;
  }

  /// 可用項目 (非封存)
  List<GearLibraryItem> get availableItems => items.where((i) => !i.isArchived).toList();

  /// 依分類分組
  Map<String, List<GearLibraryItem>> get itemsByCategory {
    final result = <String, List<GearLibraryItem>>{};
    for (final cat in GearCategory.all) {
      final filtered = filteredItems.where((item) => item.category == cat).toList();
      if (filtered.isNotEmpty) {
        result[cat] = filtered;
      }
    }
    return result;
  }

  @override
  List<Object?> get props => [items, selectedCategory, searchQuery];
}

class GearLibraryError extends GearLibraryState {
  final String message;

  const GearLibraryError(this.message);

  @override
  List<Object?> get props => [message];
}
