import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// App 全域使用的網路圖片元件，支援快取功能
///
/// 封裝 [CachedNetworkImage] 以提供一致的：
/// - 離線支援 (優先讀取快取/失敗備案)
/// - 載入中佔位圖/Shimmer 效果
/// - 錯誤處理
/// - 主題適配
class SummitImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SummitImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // If URL is empty, show placeholder immediately
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Fade in effect for smoother UX
      fadeInDuration: const Duration(milliseconds: 300),
      // Placeholder while downloading
      placeholder: (context, url) => _buildPlaceholder(context),
      // Error widget (e.g. 404 or no network + no cache)
      errorWidget: (context, url, error) => _buildErrorWidget(context),
      // CacheManager: DefaultCacheManager is used by default.
      // It handles:
      // 1. Storing files in temp/lib directory
      // 2. LRU (Least Recently Used) cleanup
      // 3. checking cache-control headers (if configured)
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade200,
      child: Center(child: Icon(Icons.image, size: 24, color: theme.disabledColor.withValues(alpha: 0.2))),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      color: isDark ? theme.colorScheme.surfaceContainer : Colors.grey.shade300,
      child: Center(child: Icon(Icons.broken_image, size: 24, color: theme.disabledColor)),
    );
  }
}
