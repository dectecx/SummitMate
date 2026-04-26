import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import 'member_management_screen.dart';
import 'package:summitmate/core/core.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../core/di/injection.dart';
import '../../core/services/permission_service.dart';
import '../../presentation/cubits/settings/settings_cubit.dart';
import '../../presentation/cubits/settings/settings_state.dart';

import '../widgets/common/modern_sliver_app_bar.dart';
import '../widgets/trip/trip_card.dart';
import '../widgets/trip/create_trip_dialog.dart';
import '../widgets/trip/cloud_sync_bar.dart';
import '../utils/tutorial_keys.dart';
import '../widgets/responsive_layout.dart';

/// 行程列表畫面
/// 管理多個登山計畫
class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionService = getIt<PermissionService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTripDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          UserProfile? currentUser;
          if (authState is AuthAuthenticated) {
            currentUser = authState.user;
          }

          return BlocBuilder<TripCubit, TripState>(
            builder: (context, state) {
              if (state is TripLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Trip> allTrips = [];
              String? activeTripId;

              if (state is TripLoaded) {
                allTrips = state.trips;
                activeTripId = state.activeTrip?.id;
              } else if (state is TripError) {
                return Center(child: Text('載入失敗: ${state.message}'));
              }

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

              return CustomScrollView(
                slivers: [
                  // 1. Sliver App Bar
                  ModernSliverAppBar(
                    title: '行程管理',
                    expandedHeight: 120.0,
                    background: Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.all(24),
                      child: Icon(Icons.map_outlined, size: 100, color: colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ),

                  // 2. Cloud Sync Status
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, settingsState) {
                          DateTime? lastSync;
                          if (settingsState is SettingsLoaded) {
                            lastSync = settingsState.lastSyncTime;
                          }
                          return CloudSyncBar(lastSyncTime: lastSync);
                        },
                      ),
                    ),
                  ),

                  // 3. Content
                  if (allTrips.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hiking, size: 80, color: theme.disabledColor),
                              const SizedBox(height: 16),
                              Text(
                                '尚無行程',
                                style: TextStyle(fontSize: 18, color: theme.disabledColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '開始規劃你的下一次冒險吧！',
                                style: TextStyle(color: theme.disabledColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => _showCreateTripDialog(context),
                                icon: const Icon(Icons.add),
                                label: const Text('新增行程'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Ongoing / Future
                    if (ongoingTrips.isNotEmpty) ...[
                      _buildHeaderSliver(context, Icons.directions_walk, '進行中 / 未來行程', colorScheme.primary),
                      _buildItemsSliver(context, ongoingTrips, currentUser, activeTripId, permissionService),
                    ],

                    // Archived
                    if (archivedTrips.isNotEmpty) ...[
                      _buildHeaderSliver(context, Icons.history, '已封存 / 結束行程', theme.disabledColor, topPadding: 32),
                      _buildItemsSliver(context, archivedTrips, currentUser, activeTripId, permissionService),
                    ],
                  ],

                  // Bottom spacer
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderSliver(BuildContext context, IconData icon, String title, Color color, {double topPadding = 0}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSliver(
    BuildContext context,
    List<Trip> trips,
    UserProfile? currentUser,
    String? activeTripId,
    PermissionService permissionService,
  ) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 180,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            return _buildTripItem(context, trips[index], currentUser, activeTripId, permissionService);
          }, childCount: trips.length),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildTripItem(context, trips[index], currentUser, activeTripId, permissionService);
        }, childCount: trips.length),
      ),
    );
  }

  Widget _buildTripItem(
    BuildContext context,
    Trip trip,
    UserProfile? currentUser,
    String? activeTripId,
    PermissionService permissionService,
  ) {
    final canEdit = permissionService.canEditTripSync(currentUser, trip);
    final canDelete = permissionService.canDeleteTripSync(currentUser, trip);

    final isOwner = currentUser != null && trip.userId == currentUser.id;
    final roleLabel = isOwner
        ? RoleConstants.displayName[RoleConstants.leader] ?? 'Leader'
        : RoleConstants.displayName[RoleConstants.member] ?? 'Member';

    return TripCard(
      trip: trip,
      isActive: trip.id == activeTripId,
      roleLabel: roleLabel,
      onTap: () => _onTripTap(context, trip, activeTripId, canEdit),
      onEdit: canEdit ? () => _showEditTripDialog(context, trip) : null,
      onDelete: canDelete ? () => _confirmDelete(context, trip) : null,
      onUpload: canEdit ? () => _handleFullUpload(context, trip) : null,
      onManageMembers: () => _navigateToMembers(context, trip),
      memberBtnKey: trip.id == activeTripId ? TutorialKeys.tripListActiveMemberBtn : null,
    );
  }

  /// 顯示建立行程對話框
  void _showCreateTripDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const CreateTripDialog());
  }

  /// 點擊行程項目
  /// 若非當前活動行程 -> 切換為活動行程 (且不進入編輯)
  /// 若已是活動行程 -> 顯示編輯對話框 (如果有權限)
  void _onTripTap(BuildContext context, Trip trip, String? activeTripId, bool canEdit) async {
    if (trip.id != activeTripId) {
      await context.read<TripCubit>().setActiveTrip(trip.id);
      if (context.mounted) {
        ToastService.success('已切換到「${trip.name}」');
        Navigator.pop(context); // 返回首頁
      }
    } else {
      ToastService.info('此為當前行程');
    }
  }

  /// 顯示編輯行程對話框 (傳入 [Trip] 物件)
  void _showEditTripDialog(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => CreateTripDialog(tripToEdit: trip),
    );
  }

  /// 確認刪除行程
  void _confirmDelete(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除行程'),
        content: Text('確定要刪除「${trip.name}」嗎？\n此操作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TripCubit>().deleteTrip(trip.id);
              ToastService.success('已刪除「${trip.name}」');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  /// 處理完整行程上傳 (含裝備與行程表)
  ///
  /// 這是一個破壞性操作，會覆蓋雲端的對應資料。
  /// 使用 [TripCubit.uploadFullTrip] 執行。
  void _handleFullUpload(BuildContext context, Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('上傳/同步行程'),
        content: Text('確定要將「${trip.name}」的所有資料(含裝備、行程)同步到雲端嗎？\n若雲端已有相同 ID，將會覆蓋舊資料。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('確認上傳')),
        ],
      ),
    );

    if (confirm != true) return;

    if (context.mounted) {
      final isSuccess = await context.read<TripCubit>().uploadFullTrip(trip);
      if (isSuccess) {
        ToastService.success('行程「${trip.name}」同步成功！');
      } else {
        ToastService.error('同步失敗，請稍後再試');
      }
    }
  }

  void _navigateToMembers(BuildContext context, Trip trip) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MemberManagementScreen(trip: trip)));
  }
}
