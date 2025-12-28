import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../screens/trip_list_screen.dart';

/// 行程選擇器 Widget
/// 顯示在 AppBar 或其他位置，點擊可切換行程
class TripSelectorWidget extends StatelessWidget {
  /// 是否顯示完整版本 (包含行程名稱)
  final bool showFullVersion;

  /// 小型版本時的圖示大小
  final double iconSize;

  const TripSelectorWidget({super.key, this.showFullVersion = true, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, provider, child) {
        final activeTrip = provider.activeTrip;

        if (showFullVersion) {
          return InkWell(
            onTap: () => _navigateToTripList(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.terrain, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      activeTrip?.name ?? '選擇行程',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          );
        } else {
          // 小型版本：只顯示圖示
          return IconButton(
            onPressed: () => _navigateToTripList(context),
            icon: Icon(Icons.terrain, size: iconSize),
            tooltip: activeTrip?.name ?? '選擇行程',
          );
        }
      },
    );
  }

  void _navigateToTripList(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TripListScreen()));
  }
}

/// 行程選擇器 - 下拉選單版本
/// 適合在表單中使用
class TripDropdownSelector extends StatelessWidget {
  final void Function(String tripId)? onChanged;
  final String? selectedTripId;

  const TripDropdownSelector({super.key, this.onChanged, this.selectedTripId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, provider, child) {
        final trips = provider.trips;
        final currentId = selectedTripId ?? provider.activeTripId;

        return DropdownButtonFormField<String>(
          value: currentId,
          decoration: const InputDecoration(labelText: '選擇行程', prefixIcon: Icon(Icons.terrain)),
          items: trips.map((trip) {
            return DropdownMenuItem<String>(
              value: trip.id,
              child: Text(trip.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged != null
              ? (value) {
                  if (value != null) {
                    onChanged!(value);
                  }
                }
              : null,
        );
      },
    );
  }
}
