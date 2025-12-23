import 'package:flutter/material.dart';

/// 可點擊放大的圖片元件
/// 點擊後以滿版彈窗形式顯示，支援雙指縮放和拖曳
class ZoomableImage extends StatelessWidget {
  /// 圖片路徑 (assets 路徑)
  final String assetPath;

  /// 圖片適配方式
  final BoxFit fit;

  /// 圓角半徑 (0 = 無圓角)
  final double borderRadius;

  /// 圖片標題 (顯示於放大檢視時)
  final String? title;

  /// 是否顯示放大提示 icon
  final bool showZoomHint;

  /// 錯誤時的替代元件
  final Widget? errorWidget;

  const ZoomableImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
    this.title,
    this.showZoomHint = true,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreenViewer(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              assetPath,
              fit: fit,
              errorBuilder: (context, error, stackTrace) =>
                  errorWidget ?? Container(color: Colors.grey.shade300),
            ),
          ),
          // 右下角放大提示
          if (showZoomHint)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullscreenViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageViewerDialog(
            assetPath: assetPath,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}

/// 滿版圖片檢視器彈窗
class ImageViewerDialog extends StatefulWidget {
  final String assetPath;
  final String? title;

  const ImageViewerDialog({
    super.key,
    required this.assetPath,
    this.title,
  });

  /// 靜態方法：直接開啟圖片檢視器
  static void show(BuildContext context, {required String assetPath, String? title}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageViewerDialog(
            assetPath: assetPath,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  final TransformationController _controller = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.0) {
      // 縮回原大小
      _controller.value = Matrix4.identity();
      _currentScale = 1.0;
    } else {
      // 放大 2 倍 (中心縮放)
      _controller.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
      _currentScale = 2.0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景點擊關閉
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),

          // 可縮放的圖片
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: 0.5,
              maxScale: 4.0,
              onInteractionEnd: (details) {
                _currentScale = _controller.value.getMaxScaleOnAxis();
              },
              child: Center(
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // 頂部標題和關閉按鈕
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (widget.title != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 底部操作提示
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  '雙擊放大/縮小 • 雙指縮放 • 點擊背景關閉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
