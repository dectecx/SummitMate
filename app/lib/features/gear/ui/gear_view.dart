import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/reorderable_group.dart';
import '../../../shared/hint_banner.dart';
import '../domain/gear_logic.dart';
import '../providers.dart';
import 'gear_form_sheet.dart';
import '../../../shared/brand/illustrations.dart';
import '../../../shared/animations.dart';
import '../../../shared/icon_badge.dart';

/// "裝備": the person's own packing list for a trip, grouped by category.
class GearView extends ConsumerStatefulWidget {
  const GearView({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<GearView> createState() => _GearViewState();
}

class _GearViewState extends ConsumerState<GearView> {
  bool _reordering = false;

  @override
  Widget build(BuildContext context) {
    final tripId = widget.tripId;
    final items = ref.watch(gearProvider(tripId)).value ?? const <GearItem>[];
    if (items.isEmpty) {
      return const ComingSoon(illustration: Illustration.gear, message: '還沒有裝備。這份清單只有你看得到，按右下角開始列出要帶的東西。');
    }
    final groups = groupGear(items);
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: HintBanner(hintId: 'gear-pack', icon: Icons.backpack_outlined, text: '勾選代表已打包；這份清單只有你看得到，隊友看不到。')),
        SliverToBoxAdapter(child: _Summary(items: items)),
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: ReorderToggle(reordering: _reordering, onChanged: (v) => setState(() => _reordering = v))),
          ),
        ),
        for (final g in groups)
          ReorderableGroupSliver(
            key: ValueKey('gear-group-${g.category.key}'),
            title: g.category.label,
            icon: _iconOf(g.category),
            trailing: formatWeight(totalWeight(g.items)),
            reordering: _reordering,
            ids: [for (final i in g.items) i.id],
            onReorder: (ids) => ref.read(gearRepositoryProvider).reorder(ids),
            itemBuilder: (_, i) => _GearRow(tripId: tripId, item: g.items[i], handleIndex: _reordering ? i : null),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

IconData _iconOf(GearCategory c) => switch (c) {
  GearCategory.sleep => Icons.bed_outlined,
  GearCategory.cook => Icons.outdoor_grill_outlined,
  GearCategory.clothing => Icons.checkroom_outlined,
  GearCategory.pack => Icons.backpack_outlined,
  GearCategory.electronics => Icons.flashlight_on_outlined,
  GearCategory.safety => Icons.medical_services_outlined,
  GearCategory.other => Icons.category_outlined,
};

class _Summary extends ConsumerWidget {
  const _Summary({required this.items});
  final List<GearItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animate = animationsOn(context, ref);
    final theme = Theme.of(context);
    final packed = packedCount(items);
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('總重量', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text(formatWeight(totalWeight(items)), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                      Text('已打包 $packed / ${items.length} 項', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const IconBadge(Icons.backpack_outlined, size: 56),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(end: items.isEmpty ? 0 : packed / items.length),
              duration: Duration(milliseconds: animate ? 350 : 0),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(value: value, minHeight: 9, borderRadius: BorderRadius.circular(5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GearRow extends ConsumerWidget {
  const _GearRow({required this.tripId, required this.item, this.handleIndex});
  final String tripId;
  final GearItem item;

  /// Set in reorder mode: the row shows a drag handle and cannot be tapped or ticked.
  final int? handleIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      shape: const RoundedRectangleBorder(),
      onTap: handleIndex != null ? null : () => showGearFormSheet(context, tripId: tripId, item: item),
      leading: Checkbox(
        value: item.isChecked,
        onChanged: handleIndex != null ? null : (v) => ref.read(gearRepositoryProvider).update(item.id, isChecked: v ?? false),
      ),
      title: Text(
        item.name.isEmpty ? '（未命名）' : item.name,
        style: item.isChecked ? TextStyle(color: theme.colorScheme.outline, decoration: TextDecoration.lineThrough) : null,
      ),
      subtitle: item.quantity > 1 ? Text('${formatWeight(item.weight)} × ${item.quantity}') : null,
      trailing: handleIndex != null ? ReorderHandle(index: handleIndex!) : Text(formatWeight(lineWeight(item)), style: theme.textTheme.bodyMedium),
    );
  }
}
