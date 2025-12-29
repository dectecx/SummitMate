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
          final allTrips = tripProvider.trips;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final ongoingTrips = allTrips.where((t) {
            if (t.endDate == null) return true;
            return !t.endDate!.isBefore(today);
          }).toList();

          final archivedTrips = allTrips.where((t) {
            if (t.endDate == null) return false;
            return t.endDate!.isBefore(today);
          }).toList();

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                subtitle: Text('共 ${allTrips.length} 個行程'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context); // 關閉抽屜
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TripListScreen()));
                },
              ),
              const Divider(),

              // 進行中行程
              if (ongoingTrips.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '進行中 / 未來行程',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...ongoingTrips.map((trip) => _buildTripTile(context, trip, tripProvider)),
              ],

              // 已封存行程
              if (archivedTrips.isNotEmpty) ...[
                if (ongoingTrips.isNotEmpty) const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '已封存 / 結束行程',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                ...archivedTrips.map((trip) => _buildTripTile(context, trip, tripProvider)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTripTile(BuildContext context, dynamic trip, TripProvider provider) {
    final isActive = trip.id == provider.activeTripId;
    // Format date: "2024/05/20 - 2024/05/22"
    final start = '${trip.startDate.year}/${trip.startDate.month}/${trip.startDate.day}';
    String end = '';
    if (trip.endDate != null) {
      end = ' - ${trip.endDate!.year}/${trip.endDate!.month}/${trip.endDate!.day}';
    }

    return ListTile(
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        trip.name,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Theme.of(context).colorScheme.primary : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$start$end', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      selected: isActive,
      onTap: () async {
        if (!isActive) {
          await provider.setActiveTrip(trip.id);
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
  }
}
