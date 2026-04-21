import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:summitmate/core/core.dart';
import '../../../data/models/gear_item.dart';
import '../../cubits/gear/gear_cubit.dart';
import 'gear_mode_selector.dart';
import 'gear_item_tile.dart';
import 'dialogs/edit_gear_dialog.dart';
import 'dialogs/delete_gear_dialog.dart';

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

  void _onReorder(int oldIndex, int newIndex) async {
    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (oldIndex == adjustedNewIndex) return;

    setState(() {
      _pendingActions++;
      final item = _localItems.removeAt(oldIndex);
      _localItems.insert(adjustedNewIndex, item);
      _localItems = List.from(_localItems);
    });

    try {
      await context.read<GearCubit>().reorderItem(oldIndex, newIndex, category: widget.category);
    } finally {
      if (mounted) setState(() => _pendingActions--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        maintainState: true,
        initiallyExpanded: true,
        leading: Icon(GearCategoryHelper.getIcon(widget.category)),
        title: Text('${GearCategoryHelper.getName(widget.category)} (${_localItems.length}件)'),
        subtitle: Text(
          WeightFormatter.format(_localItems.fold<double>(0, (sum, item) => sum + item.totalWeight), decimals: 0),
        ),
        children: [
          ReorderableListView(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _onReorder,
            children: _localItems.map((item) {
              return GearItemTile(
                key: ValueKey(item.key),
                item: item,
                mode: widget.mode,
                onToggle: () => context.read<GearCubit>().toggleChecked(item.key),
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
            }).toList(),
          ),
        ],
      ),
    );
  }
}
