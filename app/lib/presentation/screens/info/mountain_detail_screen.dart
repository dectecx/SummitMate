import 'package:flutter/material.dart';

import 'package:summitmate/data/models/mountain_location.dart';
import 'package:summitmate/presentation/widgets/common/summit_image.dart';
import 'package:summitmate/presentation/widgets/info/external_links_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/favorites/mountain/mountain_favorites_cubit.dart';
import 'package:summitmate/presentation/cubits/favorites/mountain/mountain_favorites_state.dart';

/// 山岳詳細資料頁面
///
/// 顯示特定山岳的完整資訊，包含：
/// - 頂部 Hero 圖片與基本資訊 (海拔/難度/地點)
/// - 詳細介紹與特色
/// - 交通與地圖資訊
/// - 天氣預報連結與收藏功能
class MountainDetailScreen extends StatelessWidget {
  final MountainLocation mountain;

  const MountainDetailScreen({super.key, required this.mountain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => Navigator.pop(context),
                  tooltip: '返回',
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                  child: BlocBuilder<MountainFavoritesCubit, MountainFavoritesState>(
                    builder: (context, state) {
                      final isFav = context.read<MountainFavoritesCubit>().isFavorite(mountain.id);
                      return IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                        onPressed: () {
                          context.read<MountainFavoritesCubit>().toggleFavorite(mountain.id);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFav ? '已從收藏移除' : '已加入收藏'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        tooltip: isFav ? '取消收藏' : '加入收藏',
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  mountain.photoUrls.isNotEmpty
                      ? SummitImage(imageUrl: mountain.photoUrls.first, fit: BoxFit.cover)
                      : _buildPlaceholder(theme),
                  // Scrim gradient for text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            mountain.category.label,
                            style: TextStyle(color: colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mountain.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${mountain.region.label} • ${mountain.jurisdiction}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Info Grid
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -12), // Pull up slightly
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(child: _buildInfoCard(context, '海拔', '${mountain.altitude}m', Icons.terrain)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            '難度',
                            mountain.isBeginnerFriendly ? '新手' : '一般',
                            mountain.isBeginnerFriendly ? Icons.eco : Icons.directions_walk,
                            color: mountain.isBeginnerFriendly ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Introduction
                    _buildSectionTitle(context, '關於 ${mountain.name}'),
                    const SizedBox(height: 12),
                    Text(
                      mountain.introduction,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: theme.textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 32),

                    // Features
                    _buildSectionTitle(context, '特色亮點'),
                    const SizedBox(height: 12),
                    Text(
                      mountain.features,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: theme.textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 32),

                    // Trails Info
                    _buildSectionTitle(context, '基本資訊'),
                    const SizedBox(height: 16),
                    _buildDetailRow(context, Icons.directions, '主要登山口', mountain.trailheads.join(', ')),
                    const SizedBox(height: 16),
                    _buildDetailRow(context, Icons.map, '地圖參考', mountain.mapRef),
                    const SizedBox(height: 32),

                    // External Links
                    _buildSectionTitle(context, '實用連結'),
                    const SizedBox(height: 16),
                    ExternalLinksCard(location: mountain),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: Center(child: Icon(Icons.landscape, size: 64, color: theme.disabledColor)),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: baseColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.iconTheme.color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
