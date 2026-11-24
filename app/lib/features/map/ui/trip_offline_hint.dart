import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import '../maplibre/rudy_providers.dart';

/// Reminder on a trip with a main mountain: install the Rudy Map before leaving.
/// Shows nothing when the trip has no mountain, is over, or the Rudy Map is already on the phone.
class TripOfflineHint extends ConsumerWidget {
  const TripOfflineHint({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trip.mountainId == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    if (trip.end.isBefore(DateTime(now.year, now.month, now.day))) return const SizedBox.shrink();
    if (ref.watch(rudyReadyProvider).value ?? true) return const SizedBox.shrink(); // installed (or not known yet)

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
                Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(child: Text('出發前先下載魯地圖離線地圖，山上沒有訊號也能看')),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                key: const ValueKey('trip-offline-download'),
                onPressed: () => context.push(Routes.offlineMaps),
                child: const Text('前往下載'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
