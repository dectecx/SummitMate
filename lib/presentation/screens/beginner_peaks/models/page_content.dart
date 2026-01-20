import 'package:flutter/material.dart';
import 'peak_data.dart';

/// 頁面內容基類，用於 PageView 的多型顯示
abstract class PageContent {
  /// 頁籤選單標題
  String get menuTitle;

  /// 背景主題色
  Color get bgColor;
}

/// 資訊簡介頁面 (第一頁)
class InfoPageContent extends PageContent {
  @override
  String get menuTitle => '指南簡介';
  @override
  Color get bgColor => Colors.teal;
}

/// 分類資料頁面 (包含該分類下的山岳列表)
class CategoryData extends PageContent {
  /// 分類標題 (例如：一、快樂大景型)
  final String title;

  /// 分類副標題
  final String subtitle;

  /// 主題顏色
  final Color color;

  /// 該分類下的山岳列表
  final List<PeakData> peaks;

  CategoryData({required this.title, required this.subtitle, required this.color, required this.peaks});

  @override
  String get menuTitle => title.split('、').last.replaceAll('型', '');
  @override
  Color get bgColor => color;
}
