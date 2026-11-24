import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/hint_banner.dart';
import '../domain/gear_logic.dart';
import '../providers.dart';
import 'gear_form_sheet.dart';
import '../../../shared/brand/illustrations.dart';

/// "裝備": the person's own packing list for a trip, grouped by category.
class GearView extends ConsumerWidget {
  const GearView({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(gearProvider(tripId)).value ?? const <GearItem>[];
    if (items.isEmpty) {
      return const ComingSoon(illustration: Illustration.gear, message: '還沒有裝備。這份清單只有你看得到，按右下角開始列出要帶的東西。');
    }
    final groups = groupGear(items);
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const HintBanner(hintId: 'gear-pack', icon: Icons.backpack_outlined, text: '勾選代表已打包；這份清單只有你看得到，隊友看不到。'),
        _Summary(items: items),
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(child: Text(g.category.label, style: Theme.of(context).textTheme.titleSmall)),
                Text(formatWeight(totalWeight(g.items)), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          for (final item in g.items) _GearRow(tripId: tripId, item: item),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.items});
  final List<GearItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packed = packedCount(items);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('總重量', style: theme.textTheme.bodyMedium)),
                Text(formatWeight(totalWeight(items)), style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: items.isEmpty ? 0 : packed / items.length, minHeight: 6, borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 8),
            Text('已打包 $packed / ${items.length} 項', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _GearRow extends ConsumerWidget {
  const _GearRow({required this.tripId, required this.item});
  final String tripId;
  final GearItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => showGearFormSheet(context, tripId: tripId, item: item),
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (v) => ref.read(gearRepositoryProvider).update(item.id, isChecked: v ?? false),
      ),
      title: Text(
        item.name.isEmpty ? '（未命名）' : item.name,
        style: item.isChecked ? TextStyle(color: theme.colorScheme.outline, decoration: TextDecoration.lineThrough) : null,
      ),
      subtitle: item.quantity > 1 ? Text('${formatWeight(item.weight)} × ${item.quantity}') : null,
      trailing: Text(formatWeight(lineWeight(item)), style: theme.textTheme.bodyMedium),
    );
  }
}
