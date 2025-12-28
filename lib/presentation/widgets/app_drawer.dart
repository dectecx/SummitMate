import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../providers/itinerary_provider.dart';
import '../providers/message_provider.dart';
import '../screens/trip_list_screen.dart';

/// 應用程式側邊欄 (Drawer)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<TripProvider>(
        builder: (context, tripProvider, child) {
          final activeTrip = tripProvider.activeTrip;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.terrain, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      activeTrip?.name ?? '選擇行程',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (activeTrip != null)
                      Text(
                        '${activeTrip.durationDays} 天行程',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('管理行程'),
                subtitle: Text('共 ${tripProvider.trips.length} 個行程'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context); // 關閉抽屜
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TripListScreen()));
                },
              ),
              const Divider(),
              // 快速切換行程
              if (tripProvider.trips.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '快速切換',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                ...tripProvider.trips.take(5).map((trip) {
                  final isActive = trip.id == tripProvider.activeTripId;
                  return ListTile(
                    leading: Icon(
                      isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isActive ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      trip.name,
                      style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: isActive,
                    onTap: () async {
                      if (!isActive) {
                        await tripProvider.setActiveTrip(trip.id);
                        // 重新載入相關 Provider
                        if (context.mounted) {
                          context.read<ItineraryProvider>().reload();
                          context.read<MessageProvider>().reload();
                          Navigator.pop(context); // 關閉抽屜
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}
