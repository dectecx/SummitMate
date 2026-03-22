import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../../core/theme.dart';
import 'package:summitmate/domain/domain.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import '../cubits/gear/gear_cubit.dart';
import '../cubits/gear_library/gear_library_cubit.dart';
import '../cubits/message/message_cubit.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/meal/meal_cubit.dart';
import '../screens/trip_list_screen.dart';
import '../screens/group_events_list_screen.dart';
import '../../data/models/trip.dart';
import '../utils/tutorial_keys.dart';

/// 應用程式側邊欄 (Drawer)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        // Prepare Theme Strategy
        AppThemeType currentTheme = AppThemeType.nature;
        if (settingsState is SettingsLoaded) {
          currentTheme = settingsState.settings.theme;
        }
        final strategy = AppTheme.getStrategy(currentTheme);

        return Drawer(
          backgroundColor: Colors.transparent, // Transparent to show gradient
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              gradient: strategy.drawerGradient,
            ),
            child: BlocBuilder<TripCubit, TripState>(
              builder: (context, tripState) {
                final activeTrip = tripState is TripLoaded ? tripState.activeTrip : null;
                final allTrips = tripState is TripLoaded ? tripState.trips : <Trip>[];

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final ongoingTrips = allTrips.where((t) {
                  final end = t.endDate ?? t.startDate;
                  return !end.isBefore(today);
                }).toList();

                final archivedTrips = allTrips.where((t) {
                  final end = t.endDate ?? t.startDate;
                  return end.isBefore(today);
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
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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
                      key: TutorialKeys.drawerManageTrips,
                      onTap: () {
                        Navigator.pop(context); // 關閉抽屜
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TripListScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.hiking),
                      title: const Text('揪團活動'),
                      subtitle: const Text('找隊友 / 建立揪團'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context); // 關閉抽屜
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupEventsListScreen()));
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
                      ...ongoingTrips.map((trip) => _buildTripTile(context, trip, activeTrip?.id)),
                    ],

                    // 已封存行程
                    if (archivedTrips.isNotEmpty) ...[
                      if (ongoingTrips.isNotEmpty) const Divider(indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          '已封存 / 結束行程',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                      ...archivedTrips.map((trip) => _buildTripTile(context, trip, activeTrip?.id)),
                    ],

                    // Auth Section
                    const Divider(),
                    _buildAuthSection(context),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthSection(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        // Use SettingsCubit for user info
        final username = settingsState is SettingsLoaded ? settingsState.username : '...';
        final avatar = settingsState is SettingsLoaded ? settingsState.avatar : '🐻';

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isGuest = authState is! AuthAuthenticated || authState.isGuest;
            final email = authState is AuthAuthenticated ? authState.email : null;

            if (isGuest) {
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('訪客模式'),
                subtitle: const Text('登入以同步資料'),
                trailing: TextButton(
                  onPressed: () {
                    // Logout to login screen
                    context.read<AuthCubit>().logout();
                  },
                  child: const Text('登入'),
                ),
              );
            }

            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(avatar, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email ?? '', style: const TextStyle(fontSize: 12)),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('登出', style: TextStyle(color: Colors.red)),
                  onTap: () => _handleLogout(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Check network status (Synchronous check via Service)
    final hasConnection = getIt<IConnectivityService>().hasConnection;

    if (!hasConnection) {
      // Offline - show warning
      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text('離線模式'),
              ],
            ),
            content: const Text(
              '您目前處於離線狀態。\n\n'
              '如果現在登出，在恢復網路連線前，您將無法重新登入。\n\n'
              '確定要登出嗎？',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('確定登出'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }
    }

    // Proceed with logout
    // Close drawer first before auth state change triggers HomeScreen rebuild
    if (context.mounted) {
      Navigator.pop(context); // Close drawer
    }

    // Reset all Provider states (in-memory only)
    // Hive data is preserved for offline access on next login
    if (context.mounted) {
      context.read<TripCubit>().reset();
      context.read<ItineraryCubit>().reset();
      context.read<GearCubit>().reset();
      context.read<GearLibraryCubit>().reset();
      context.read<MessageCubit>().reset();
      context.read<PollCubit>().reset();
      context.read<MealCubit>().reset();
      // Settings managed by Cubit, persistence is desired

      // Clear session token only
      context.read<AuthCubit>().logout();
    }
  }

  Widget _buildTripTile(BuildContext context, dynamic trip, String? activeTripId) {
    final isActive = trip.id == activeTripId;
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
          await context.read<TripCubit>().setActiveTrip(trip.id);
          // 重新載入相關 Provider
          if (context.mounted) {
            context.read<ItineraryCubit>().loadItinerary();
            context.read<MessageCubit>().reset();
            Navigator.pop(context); // 關閉抽屜
          }
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}
