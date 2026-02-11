import 'package:flutter/material.dart';

/// 現代化風格的 SliverAppBar (包含動態標題縮排效果)
class ModernSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final String? backgroundImageUrl; // 可選：預留給未來擴充或自訂背景圖片
  final Widget? background; // 自訂背景 Widget
  final double expandedHeight;

  const ModernSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundImageUrl,
    this.background,
    this.expandedHeight = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.canvasColor,
      surfaceTintColor: theme.appBarTheme.surfaceTintColor,
      actions: actions,
      leading: const BackButton(),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final minHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

          // 計算轉場進度 t (0.0 = 收合, 1.0 = 展開)
          final range = expandedHeight - minHeight;
          final t = range > 0 ? ((top - minHeight) / range).clamp(0.0, 1.0) : 0.0;

          // 計算左側內縮：60 (收合) -> 16 (展開)
          final leftPadding = 60.0 + (16.0 - 60.0) * t;

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16, right: 16),
            title: Text(
              title,
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            background:
                background ??
                Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(24),
                  child: Icon(Icons.terrain, size: 100, color: colorScheme.primary.withValues(alpha: 0.1)), // 預設通用圖示
                ),
          );
        },
      ),
    );
  }
}
