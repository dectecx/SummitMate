import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/gear_utils.dart';
import '../../../domain/entities/gear_item.dart';
import '../../cubits/gear/gear_cubit.dart';
import 'gear_mode_selector.dart';
import 'gear_item_tile.dart';
import 'dialogs/edit_gear_dialog.dart';
import 'dialogs/delete_gear_dialog.dart';

/// 單一裝備分類區塊。
///
/// 以 **Sliver** 形式輸出（回傳 [SliverMainAxisGroup]），需放入 [CustomScrollView]
/// 的 `slivers` 中，使項目能 lazy 建構，避免巢狀 `shrinkWrap` 反模式。
/// - 檢視模式：使用 [SliverList] 純列表。
/// - 編輯模式：使用 [SliverReorderableList]，長按項目即可拖曳排序（排序仍以分類為單位）。
class GearCategorySection extends StatefulWidget {
  final String category;
  final List<GearItem> items;
  final GearListMode mode;

  const GearCategorySection({super.key, required this.category, required this.items, required this.mode});

  @override
  State<GearCategorySection> createState() => _GearCategorySectionState();
}

class _GearCategorySectionState extends State<GearCategorySection> {
  late List<GearItem> _localItems;
  int _pendingActions = 0;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(GearCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pendingActions == 0 && !listEquals(_localItems, widget.items)) {
      setState(() {
        _localItems = List.from(widget.items);
      });
    }
  }

  /// [SliverReorderableList.onReorderItem] 提供的 newIndex 已針對「移除 oldIndex 後」調整過，
  /// 可直接用於本地樂觀更新；而 [GearCubit.reorderItem] 仍採傳統 ReorderableListView
  /// 慣例（移除前的插入槽），故在呼叫前還原為 rawNewIndex。
  void _onReorderItem(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    setState(() {
      _pendingActions++;
      final item = _localItems.removeAt(oldIndex);
      _localItems.insert(newIndex, item);
      _localItems = List.from(_localItems);
    });

    final rawNewIndex = newIndex >= oldIndex ? newIndex + 1 : newIndex;
    try {
      await context.read<GearCubit>().reorderItem(oldIndex, rawNewIndex, category: widget.category);
    } finally {
      if (mounted) setState(() => _pendingActions--);
    }
  }

  GearItemTile _buildTile(GearItem item) {
    return GearItemTile(
      key: ValueKey(item.id),
      item: item,
      mode: widget.mode,
      onToggle: () => context.read<GearCubit>().toggleChecked(item.id),
      onTap: () {
        if (widget.mode == GearListMode.view) {
          EditGearDialog.show(context, item);
        }
      },
      onDelete: () => DeleteGearDialog.show(context, item),
      onIncrease: () => context.read<GearCubit>().updateQuantity(item, item.quantity + 1),
      onDecrease: () {
        if (item.quantity > 1) {
          context.read<GearCubit>().updateQuantity(item, item.quantity - 1);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalWeight = _localItems.fold<double>(0, (sum, item) => sum + item.totalWeight);

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 12),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme, totalWeight)),
            if (_expanded) _buildItemsSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, double totalWeight) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(GearCategoryHelper.getIcon(widget.category)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${GearCategoryHelper.getName(widget.category)} (${_localItems.length}件)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(WeightFormatter.format(totalWeight, decimals: 0), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSliver() {
    if (widget.mode == GearListMode.edit) {
      return SliverReorderableList(
        itemCount: _localItems.length,
        onReorderItem: _onReorderItem,
        itemBuilder: (context, index) {
          final item = _localItems[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(item.id),
            index: index,
            child: _buildTile(item),
          );
        },
      );
    }

    return SliverList.builder(
      itemCount: _localItems.length,
      itemBuilder: (context, index) => _buildTile(_localItems[index]),
    );
  }
}
