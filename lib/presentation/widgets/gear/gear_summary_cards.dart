import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:summitmate/core/core.dart';
import '../../screens/gear_cloud_screen.dart';
import '../../screens/gear_library_screen.dart';
import '../../screens/meal_planner_screen.dart';
import 'package:summitmate/data/models/mountain_location.dart';

/// 快速連結按鈕列 (官方清單、雲端庫、我的庫)
class GearQuickLinks extends StatelessWidget {
  const GearQuickLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 官方建議裝備清單
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () async {
                final url = MountainData.jiamingLake.getLinkUrl(LinkType.gearPdf);
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    debugPrint('無法開啟連結: $url');
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.description, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(height: 8),
                    const Text('官方清單', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 雲端裝備庫 (分享用)
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GearCloudScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.cloud, color: Theme.of(context).colorScheme.secondary, size: 28),
                    const SizedBox(height: 8),
                    const Text('雲端庫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 我的裝備庫 (個人)
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GearLibraryScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.backpack, color: Theme.of(context).colorScheme.tertiary, size: 28),
                    const SizedBox(height: 8),
                    const Text('我的庫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 總重量卡片
class GearTotalWeightCard extends StatelessWidget {
  final double totalWeight;

  const GearTotalWeightCard({super.key, required this.totalWeight});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('總重量 (含糧食)', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            Text(
              '${totalWeight.toStringAsFixed(2)} kg',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 糧食計畫入口卡片
class GearMealCard extends StatelessWidget {
  final double mealWeight;

  const GearMealCard({super.key, required this.mealWeight});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bento, color: Theme.of(context).colorScheme.tertiary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('糧食計畫', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      mealWeight > 0 ? '已規劃 ${mealWeight.toStringAsFixed(2)} kg' : '尚未規劃',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
