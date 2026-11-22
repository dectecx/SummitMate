import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../explore/domain/mountain_models.dart';
import '../../explore/providers.dart';
import '../data/offline_manager.dart';
import '../domain/offline_regions.dart';
import '../providers.dart';

/// Reminder on a trip with a main mountain: download that mountain's offline map before leaving.
/// Shows nothing when the trip has no mountain or no detailed area covers it.
class TripOfflineHint extends ConsumerWidget {
  const TripOfflineHint({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = trip.mountainId;
    if (id == null) return const SizedBox.shrink();
    final mountain = switch (ref.watch(mountainsProvider).value) {
      MountainsReady(:final data) => data.byId(id),
      _ => null,
    };
    if (mountain == null) return const SizedBox.shrink();
    final region = offlineRegionFor(mountain.latitude, mountain.longitude);
    if (region == null) return const SizedBox.shrink();
    final row = (ref.watch(offlineRegionsProvider).value ?? const <OfflineRegion>[]).where((r) => r.id == region.id).firstOrNull;
    final theme = Theme.of(context);

    final (icon, text, action) = switch (row?.state) {
      OfflineState.done => (Icons.download_done, '「${region.name}」離線地圖已下載，山上沒訊號也能看。', null),
      OfflineState.queued || OfflineState.downloading => (Icons.downloading, '「${region.name}」離線地圖下載中，到「地圖」分頁可看進度。', null),
      _ => (Icons.map_outlined, '山上沒有訊號，出發前先下載「${region.name}」離線地圖（約 ${formatBytes(region.estimatedBytes)}）。', '下載'),
    };
    return Card(
      key: const ValueKey('trip-offline-hint'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
            if (action != null)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  key: const ValueKey('trip-offline-download'),
                  onPressed: () {
                    ref.read(offlineManagerProvider).start(region.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已加入下載：${region.name}（可切到背景繼續）')));
                  },
                  child: Text(action),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
