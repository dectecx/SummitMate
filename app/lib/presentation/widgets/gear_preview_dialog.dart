import 'package:flutter/material.dart';

import 'package:summitmate/core/core.dart';

import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';

/// 裝備組合預覽對話框
/// 使用 GearCategoryHelper 確保與主裝備頁一致
class GearPreviewDialog extends StatefulWidget {
  final GearSet gearSet;

  /// 可選：加入我的裝備庫 callback
  final Future<void> Function(List<GearItem>)? onAddToLibrary;

  const GearPreviewDialog({super.key, required this.gearSet, this.onAddToLibrary});

  @override
  State<GearPreviewDialog> createState() => _GearPreviewDialogState();
}

class _GearPreviewDialogState extends State<GearPreviewDialog> {
  // 記錄哪些類別是展開的 (預設全部展開)
  final Set<String> _expandedCategories = {};
  bool _initialized = false;

  List<GearItem> get items => widget.gearSet.items ?? [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // 預設展開所有類別
      final categories = items.map((e) => e.category).toSet();
      _expandedCategories.addAll(categories);
      _initialized = true;
    }
  }

  /// 依類別分組
  Map<String, List<GearItem>> get groupedItems {
    final map = <String, List<GearItem>>{};
    for (final item in items) {
      final category = item.category.isEmpty ? GearCategory.other : item.category;
      map.putIfAbsent(category, () => []).add(item);
    }
    return map;
  }

  /// 有序的類別列表
  List<String> get sortedCategories {
    final keys = groupedItems.keys.toList();
    keys.sort(GearCategoryHelper.compareCategories);
    return keys;
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(widget.gearSet.visibilityIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.gearSet.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('@${widget.gearSet.author}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                  _StatChip(icon: Icons.backpack, value: '${items.length}', label: '件裝備'),
                  _StatChip(icon: Icons.fitness_center, value: WeightFormatter.format(totalWeight), label: '總重量'),
                ],
              ),
            ),

            const Divider(height: 1),

            // 裝備列表 (按類別分組，可縮合)
            Flexible(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(padding: EdgeInsets.all(32), child: Text('此組合沒有裝備項目')),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final category in sortedCategories) ...[
                          _buildCategoryHeader(category),
                          if (_expandedCategories.contains(category))
                            ...groupedItems[category]!.map((item) => _GearItemTile(item: item)),
                        ],
                      ],
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
                          child: Text('下載將覆蓋您目前的裝備清單', style: TextStyle(color: Colors.orange, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                      // 加入我的庫按鈕 (如果有提供 callback)
                      if (widget.onAddToLibrary != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await widget.onAddToLibrary!(items);
                            if (context.mounted) Navigator.pop(context, false);
                          },
                          icon: const Icon(Icons.backpack, size: 18),
                          label: const Text('加入我的庫'),
                        ),
                      ],
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

  Widget _buildCategoryHeader(String category) {
    final isExpanded = _expandedCategories.contains(category);
    final itemsInCategory = groupedItems[category] ?? [];
    final categoryWeight = itemsInCategory.fold<double>(0, (sum, item) => sum + item.weight);

    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCategories.remove(category);
          } else {
            _expandedCategories.add(category);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.grey.shade100,
        child: Row(
          children: [
            Icon(GearCategoryHelper.getIcon(category), size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(GearCategoryHelper.getName(category), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(
              '${itemsInCategory.length} 件 • ${WeightFormatter.format(categoryWeight)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
      leading: Icon(GearCategoryHelper.getIcon(item.category), size: 20, color: Colors.grey.shade600),
      title: Text(item.name, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        WeightFormatter.formatPrecise(item.weight),
        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
      ),
    );
  }
}
