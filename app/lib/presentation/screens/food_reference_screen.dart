import 'package:flutter/material.dart';
import '../widgets/zoomable_image.dart';

/// 乾燥飯比較參考 - 使用統一的 ImageViewerDialog
class FoodReferenceScreen {
  FoodReferenceScreen._();

  /// 開啟乾燥飯比較圖
  static void show(BuildContext context) {
    ImageViewerDialog.show(context, assetPath: 'assets/images/dried_rice_comparison.png', title: '乾燥飯比較參考');
  }
}
