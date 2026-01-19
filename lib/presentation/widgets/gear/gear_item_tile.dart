import 'package:flutter/material.dart';

import '../../../data/models/gear_item.dart';
import 'gear_mode_selector.dart';

/// 單項裝備列表 Tile
class GearItemTile extends StatelessWidget {
  final GearItem item;
  final GearListMode mode;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const GearItemTile({
    super.key,
    required this.item,
    required this.mode,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: mode == GearListMode.view ? Checkbox(value: item.isChecked, onChanged: (_) => onToggle()) : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              item.name,
              style: TextStyle(
                decoration: _shouldStrikeThrough ? TextDecoration.lineThrough : null,
                color: _shouldStrikeThrough ? Colors.grey : null,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.quantity > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${item.quantity}',
                style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          if (item.libraryItemId != null && mode == GearListMode.view) ...[
            const SizedBox(width: 4),
            const Icon(Icons.link, size: 16, color: Colors.blue),
          ],
        ],
      ),
      subtitle: mode == GearListMode.view ? Text('${item.weight.toStringAsFixed(0)}g / ${item.category}') : null,
      trailing: mode == GearListMode.edit
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                  onPressed: onDecrease,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: onIncrease,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          : Text('${(item.totalWeight).toStringAsFixed(0)}g'),
      onTap: onTap,
    );
  }

  bool get _shouldStrikeThrough => mode == GearListMode.view && item.isChecked;
}
