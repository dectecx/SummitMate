import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/gear_helpers.dart';
import '../../../data/models/gear_item.dart';
import '../../cubits/gear/gear_cubit.dart';
import 'gear_mode_selector.dart';
import 'gear_item_tile.dart';
import 'dialogs/edit_gear_dialog.dart';
import 'dialogs/delete_gear_dialog.dart';

class GearCategorySection extends StatelessWidget {
  final String category;
  final List<GearItem> items;
  final GearListMode mode;

  const GearCategorySection({super.key, required this.category, required this.items, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        maintainState: true,
        initiallyExpanded: true,
        leading: Icon(GearCategoryHelper.getIcon(category)),
        title: Text('${GearCategoryHelper.getName(category)} (${items.length}件)'),
        subtitle: Text(
          WeightFormatter.format(items.fold<double>(0, (sum, item) => sum + item.totalWeight), decimals: 0),
        ),
        children: [
          ReorderableListView(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              context.read<GearCubit>().reorderItem(oldIndex, newIndex, category: category);
            },
            children: items.map((item) {
              return GearItemTile(
                key: ValueKey(item.key),
                item: item,
                mode: mode,
                onToggle: () => context.read<GearCubit>().toggleChecked(item.key),
                onTap: () {
                  if (mode == GearListMode.view) {
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
