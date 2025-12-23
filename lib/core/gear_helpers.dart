import 'package:flutter/material.dart';

/// 裝備分類輔助工具
/// 集中管理分類相關的 icon、名稱、顏色等，避免重複定義
class GearCategoryHelper {
  GearCategoryHelper._();

  /// 分類常數
  static const String sleep = 'Sleep';
  static const String cook = 'Cook';
  static const String wear = 'Wear';
  static const String other = 'Other';

  /// 所有分類 (有序)
  static const List<String> allCategories = [sleep, cook, wear, other];

  /// 取得分類 Icon
  static IconData getIcon(String category) {
    switch (category) {
      case sleep:
        return Icons.bed;
      case cook:
        return Icons.restaurant;
      case wear:
        return Icons.checkroom;
      case other:
        return Icons.category;
      default:
        return Icons.inventory_2;
    }
  }

  /// 取得分類顯示名稱
  static String getName(String category) {
    switch (category) {
      case sleep:
        return '睡眠系統';
      case cook:
        return '炊具與飲食';
      case wear:
        return '穿著';
      case other:
        return '其他';
      default:
        return category;
    }
  }

  /// 取得分類顏色
  static Color getColor(String category) {
    switch (category) {
      case sleep:
        return Colors.indigo;
      case cook:
        return Colors.orange;
      case wear:
        return Colors.teal;
      case other:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 取得分類排序索引 (用於排序)
  static int getSortIndex(String category) {
    final index = allCategories.indexOf(category);
    return index == -1 ? 999 : index;
  }

  /// 依分類排序
  static int compareCategories(String a, String b) {
    return getSortIndex(a).compareTo(getSortIndex(b));
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
