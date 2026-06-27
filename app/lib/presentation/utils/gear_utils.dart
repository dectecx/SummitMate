import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme/theme_extensions.dart';

/// 裝備分類輔助工具
/// 集中管理分類相關的 icon、名稱、顏色等，避免重複定義
class GearCategoryHelper {
  GearCategoryHelper._();

  /// 取得分類 Icon
  static IconData getIcon(String category) {
    switch (category) {
      case GearCategory.sleep:
        return Icons.bed;
      case GearCategory.cook:
        return Icons.restaurant;
      case GearCategory.wear:
        return Icons.checkroom;
      case GearCategory.other:
        return Icons.category;
      default:
        return Icons.inventory_2;
    }
  }

  /// 取得分類顯示名稱
  static String getName(String category) {
    switch (category) {
      case GearCategory.sleep:
        return '睡眠系統';
      case GearCategory.cook:
        return '炊具與飲食';
      case GearCategory.wear:
        return '穿著';
      case GearCategory.other:
        return '其他';
      default:
        return category;
    }
  }

  /// 取得分類顏色
  static Color getColor(String category, BuildContext context) {
    final categoryColors = Theme.of(context).extension<CategoryColors>();
    if (categoryColors != null) {
      return categoryColors.getGearColor(category);
    }
    switch (category) {
      case GearCategory.sleep:
        return Colors.indigo;
      case GearCategory.cook:
        return Colors.orange;
      case GearCategory.wear:
        return Colors.teal;
      case GearCategory.other:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 取得分類排序索引 (用於排序)
  static int getSortIndex(String category) {
    final index = GearCategory.all.indexOf(category);
    return index == -1 ? 999 : index;
  }

  /// 依分類排序
  static int compareCategories(String a, String b) {
    return getSortIndex(a).compareTo(getSortIndex(b));
  }
}

/// 裝備篩選與分組共用工具
///
/// 適用於不同 entity 型別 (如 [GearItem] / [GearLibraryItem])，透過 selector
/// closure 取得 category / name / isChecked 欄位，避免在 state 與 widget 各寫一份。
class GearFilter {
  GearFilter._();

  /// 通用篩選：依分類、未打包、搜尋關鍵字過濾
  ///
  /// [categoryOf]／[nameOf] 為必填的欄位取值 closure；
  /// [isCheckedOf] 為選填，僅在 [showUncheckedOnly] 為 true 時用於過濾未打包項目。
  static List<T> filter<T>(
    List<T> items, {
    required String Function(T) categoryOf,
    required String Function(T) nameOf,
    String? selectedCategory,
    String searchQuery = '',
    bool showUncheckedOnly = false,
    bool Function(T)? isCheckedOf,
  }) {
    var result = items;

    if (selectedCategory != null) {
      result = result.where((item) => categoryOf(item) == selectedCategory).toList();
    }

    if (showUncheckedOnly && isCheckedOf != null) {
      result = result.where((item) => !isCheckedOf(item)).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((item) => nameOf(item).toLowerCase().contains(query)).toList();
    }

    return result;
  }

  /// 依 [GearCategory.all] 的順序將項目分組（空分類略過）
  static Map<String, List<T>> groupByCategory<T>(List<T> items, {required String Function(T) categoryOf}) {
    final result = <String, List<T>>{};
    for (final cat in GearCategory.all) {
      final filtered = items.where((item) => categoryOf(item) == cat).toList();
      if (filtered.isNotEmpty) {
        result[cat] = filtered;
      }
    }
    return result;
  }
}

/// 重量格式化輔助工具
class WeightFormatter {
  WeightFormatter._();

  /// 格式化重量 (自動選擇 g 或 kg)
  static String format(double weight, {int decimals = 1}) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(decimals)} kg';
    }
    return '${weight.toStringAsFixed(0)} g';
  }

  /// 格式化重量 (精確版，用於單項顯示)
  static String formatPrecise(double weight) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(2)} kg';
    }
    return '${weight.toStringAsFixed(0)} g';
  }
}
