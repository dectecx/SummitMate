import 'package:flutter/material.dart';
import '../widgets/zoomable_image.dart';

/// 地圖檢視器 - 使用統一的 ImageViewerDialog
class MapViewerScreen {
  MapViewerScreen._();

  /// 開啟導覽地圖
  static void show(BuildContext context) {
    ImageViewerDialog.show(
      context,
      assetPath: 'assets/images/trail_map.png',
      title: '嘉明湖步道導覽圖',
    );
  }
}
