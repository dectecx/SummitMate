import 'package:flutter/material.dart';
import 'package:summitmate/data/models/mountain_location.dart';
import 'package:summitmate/presentation/widgets/common/summit_image.dart';

class MountainCard extends StatelessWidget {
  final MountainLocation mountain;
  final VoidCallback? onTap;
  final bool isFavorite;

  const MountainCard({super.key, required this.mountain, this.onTap, this.isFavorite = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Header with Badge overlap
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: SummitImage(
                        imageUrl: mountain.photoUrls.isNotEmpty ? mountain.photoUrls.first : '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Category Badge (Top Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        mountain.category.label,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Region Badge (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 12, color: theme.iconTheme.color),
                          const SizedBox(width: 4),
                          Text(
                            mountain.region.label,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            mountain.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFavorite) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: '已收藏',
                            child: Icon(
                              Icons.favorite,
                              size: 20,
                              color: isDark ? Colors.redAccent : Colors.red.shade600,
                            ),
                          ),
                        ],
                        if (mountain.isBeginnerFriendly) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: '新手推薦',
                            child: Icon(
                              Icons.eco,
                              size: 20,
                              color: isDark ? Colors.greenAccent : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${mountain.altitude}m',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: theme.disabledColor)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mountain.jurisdiction,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }
}
