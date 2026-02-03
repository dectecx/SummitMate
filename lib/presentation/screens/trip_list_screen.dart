import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import 'member_management_screen.dart';
import 'package:summitmate/core/core.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../core/di.dart';
import '../../core/services/permission_service.dart';
import '../../presentation/cubits/settings/settings_cubit.dart';
import '../../presentation/cubits/settings/settings_state.dart';

import '../widgets/common/modern_sliver_app_bar.dart';
import 'trip_cloud_screen.dart';
import '../utils/tutorial_keys.dart';

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
                          return _CloudSyncBar(lastSyncTime: lastSync);
                        },
                      ),
                    ),
                  ),

                  // 3. Content
                  if (allTrips.isEmpty)
                    // ... (rest of the content)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
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
                            Text('開始規劃你的下一次冒險吧！', style: TextStyle(color: theme.disabledColor)),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _showCreateTripDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('新增行程'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Ongoing / Future
                    if (ongoingTrips.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Icon(Icons.directions_walk, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                '進行中 / 未來行程',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final trip = ongoingTrips[index];
                            return _buildTripItem(context, trip, currentUser, activeTripId, permissionService);
                          }, childCount: ongoingTrips.length),
                        ),
                      ),
                    ],

                    // Archived
                    if (archivedTrips.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 20, color: theme.disabledColor),
                              const SizedBox(width: 8),
                              Text(
                                '已封存 / 結束行程',
                                style: TextStyle(fontSize: 14, color: theme.disabledColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final trip = archivedTrips[index];
                            return _buildTripItem(context, trip, currentUser, activeTripId, permissionService);
                          }, childCount: archivedTrips.length),
                        ),
                      ),
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

    return _TripCard(
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

/// 行程卡片 Widget
class _TripCard extends StatelessWidget {
  final Trip trip;
  final bool isActive;
  final String roleLabel;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpload;
  final VoidCallback? onManageMembers;
  final Key? memberBtnKey;

  const _TripCard({
    required this.trip,
    required this.isActive,
    required this.roleLabel,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpload,
    this.onManageMembers,
    this.memberBtnKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy/MM/dd');
    final dateText = trip.endDate != null
        ? '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate!)}'
        : dateFormat.format(trip.startDate);
    final isLeader = roleLabel == (RoleConstants.displayName[RoleConstants.leader] ?? 'Leader');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer.withValues(alpha: 0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? colorScheme.primary : theme.dividerColor.withValues(alpha: 0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? colorScheme.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActive ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [colorScheme.primary, colorScheme.tertiary]
                              : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? colorScheme.primary : Colors.grey).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.terrain, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trip.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '進行中',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLeader
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.blueGrey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isLeader
                                        ? Colors.orange.withValues(alpha: 0.3)
                                        : Colors.blueGrey.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isLeader ? Colors.orange[800] : Colors.blueGrey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.calendar_today, size: 12, color: theme.hintColor),
                              const SizedBox(width: 4),
                              Text(
                                dateText,
                                style: TextStyle(fontSize: 13, color: theme.hintColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (trip.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              trip.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: theme.hintColor.withValues(alpha: 0.8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                      icon: Icons.people_outline,
                      label: '成員',
                      onTap: onManageMembers,
                      keey: memberBtnKey,
                      color: colorScheme.primary,
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        label: '編輯',
                        onTap: onEdit,
                        color: colorScheme.secondary,
                      ),
                    ],
                    if (onUpload != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.cloud_upload_outlined,
                        label: '同步',
                        onTap: onUpload,
                        color: Colors.teal,
                      ),
                    ],
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        label: '刪除',
                        onTap: onDelete,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Key? keey;

  const _ActionButton({required this.icon, required this.label, this.onTap, this.color, this.keey});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox.shrink();

    return InkWell(
      key: keey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// 新增/編輯行程對話框
class CreateTripDialog extends StatefulWidget {
  final Trip? tripToEdit;

  const CreateTripDialog({super.key, this.tripToEdit});

  @override
  State<CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<CreateTripDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  bool get isEditing => widget.tripToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tripToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.tripToEdit?.description ?? '');
    _startDate = widget.tripToEdit?.startDate ?? DateTime.now();
    _endDate = widget.tripToEdit?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: theme.dialogBackgroundColor,
      title: Text(isEditing ? '編輯行程' : '新增行程', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: '行程名稱',
                  hintText: '例如：2024 嘉明湖三日',
                  prefixIcon: const Icon(Icons.terrain),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入行程名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date Selection Row
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerField(
                      context,
                      label: '開始日期',
                      date: _startDate,
                      onTap: () => _selectDate(isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePickerField(
                      context,
                      label: '結束日期',
                      date: _endDate,
                      placeholder: '單日',
                      isClearable: _endDate != null,
                      onTap: () => _selectDate(isStartDate: false),
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '備註 (選填)',
                  hintText: '行程描述或備忘',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
                ),
                maxLines: 3,
                minLines: 1,
              ),

              if (isEditing) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, size: 16, color: theme.hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip ID', style: TextStyle(fontSize: 10, color: theme.hintColor)),
                            SelectableText(
                              widget.tripToEdit!.id,
                              style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? '儲存變更' : '建立行程'),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    DateTime? date,
    String? placeholder,
    bool isClearable = false,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor; // Using divider color for border

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? DateFormat('yyyy/MM/dd').format(date) : (placeholder ?? '-'),
                    style: TextStyle(
                      color: date != null ? colorScheme.onSurface : theme.hintColor,
                      fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isClearable && onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.close, size: 16, color: theme.hintColor),
                  )
                else
                  Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? _startDate);
    final firstDate = isStartDate ? DateTime(2020) : _startDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // 如果結束日期早於開始日期，清除它
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final updatedTrip = Trip(
          id: widget.tripToEdit!.id,
          userId: widget.tripToEdit!.userId,
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          isActive: widget.tripToEdit!.isActive,
          createdAt: widget.tripToEdit!.createdAt,
          createdBy: widget.tripToEdit!.createdBy,
          updatedAt: widget.tripToEdit!.updatedAt,
          updatedBy: widget.tripToEdit!.updatedBy,
          // repository will update updatedAt/updatedBy
        );
        await context.read<TripCubit>().updateTrip(updatedTrip);
        if (mounted) {
          ToastService.success('行程已更新');
          Navigator.pop(context);
        }
      } else {
        await context.read<TripCubit>().addTrip(
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        );
        if (mounted) {
          ToastService.success('行程已建立');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ToastService.error('操作失敗：$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _CloudSyncBar extends StatelessWidget {
  final DateTime? lastSyncTime;

  const _CloudSyncBar({super.key, this.lastSyncTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripCloudScreen())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_sync, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('雲端同步狀態', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  if (lastSyncTime != null)
                    Text(
                      '上次同步: ${dateFormat.format(lastSyncTime!)}',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    )
                  else
                    Text('尚未同步', style: TextStyle(color: theme.hintColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
