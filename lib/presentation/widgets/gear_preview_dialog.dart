import 'package:flutter/material.dart';

import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';

/// 裝備組合預覽對話框
class GearPreviewDialog extends StatelessWidget {
  final GearSet gearSet;

  const GearPreviewDialog({
    super.key,
    required this.gearSet,
  });

  @override
  Widget build(BuildContext context) {
    final items = gearSet.items ?? [];
    final totalWeight = items.fold<double>(0, (sum, item) => sum + item.weight);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題列
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    gearSet.visibilityIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gearSet.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${gearSet.author}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 統計資訊
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    icon: Icons.backpack,
                    value: '${items.length}',
                    label: '件裝備',
                  ),
                  _StatChip(
                    icon: Icons.fitness_center,
                    value: _formatWeight(totalWeight),
                    label: '總重量',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 裝備列表
            Flexible(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('此組合沒有裝備項目'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _GearItemTile(item: item);
                      },
                    ),
            ),

            const Divider(height: 1),

            // 警告與按鈕
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '下載將覆蓋您目前的裝備清單',
                            style: TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('下載並覆蓋'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWeight(double weight) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(1)} kg';
    }
    return '${weight.toStringAsFixed(0)} g';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _GearItemTile extends StatelessWidget {
  final GearItem item;

  const _GearItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _getCategoryColor(item.category).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            _getCategoryEmoji(item.category),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        item.category,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
      trailing: Text(
        _formatItemWeight(item.weight),
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatItemWeight(double weight) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(2)} kg';
    }
    return '${weight.toStringAsFixed(0)} g';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '背負系統':
        return Colors.blue;
      case '睡眠系統':
        return Colors.purple;
      case '炊煮系統':
        return Colors.orange;
      case '衣物':
        return Colors.green;
      case '電子設備':
        return Colors.red;
      case '個人用品':
        return Colors.teal;
      case '糧食':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case '背負系統':
        return '🎒';
      case '睡眠系統':
        return '🛏️';
      case '炊煮系統':
        return '🍳';
      case '衣物':
        return '👕';
      case '電子設備':
        return '📱';
      case '個人用品':
        return '🪥';
      case '糧食':
        return '🍙';
      default:
        return '📦';
    }
  }
}
