import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import 'member_management_screen.dart';
import '../../core/constants/role_constants.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../../core/di.dart';
import '../../core/services/permission_service.dart';
import 'trip_cloud_screen.dart';
import '../utils/tutorial_keys.dart';

/// 行程列表畫面
/// 管理多個登山計畫
class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionService = getIt<PermissionService>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateTripDialog(context), tooltip: '新增行程'),
        ],
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
                if (t.endDate == null) return true;
                return !t.endDate!.isBefore(today);
              }).toList();

              final archivedTrips = allTrips.where((t) {
                if (t.endDate == null) return false;
                return t.endDate!.isBefore(today);
              }).toList();

              return Column(
                children: [
                  // 雲端同步管理按鈕
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const TripCloudScreen())),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_sync, size: 28, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              const Text('雲端同步管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 列表內容
                  Expanded(
                    child: allTrips.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hiking, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('尚無行程', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showCreateTripDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('新增行程'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              // 進行中行程
                              if (ongoingTrips.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                                  child: Text(
                                    '進行中 / 未來行程',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...ongoingTrips.map((trip) {
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
                                }),
                              ],

                              // 已封存行程
                              if (archivedTrips.isNotEmpty) ...[
                                if (ongoingTrips.isNotEmpty) const SizedBox(height: 24),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8, left: 4),
                                  child: Text(
                                    '已封存 / 結束行程',
                                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ...archivedTrips.map((trip) {
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
                                }),
                              ],
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTripDialog(context),
        child: const Icon(Icons.add),
      ),
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
    final dateFormat = DateFormat('yyyy/MM/dd');
    final dateText = trip.endDate != null
        ? '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate!)}'
        : dateFormat.format(trip.startDate);
    final shortId = trip.id.length > 8 ? trip.id.substring(0, 8) : trip.id;

    return Card(
      elevation: isActive ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面圖或圖示
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isActive ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.terrain,
                      size: 32,
                      color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 行程資訊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '當前',
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // 顯示權限角色
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: roleLabel == (RoleConstants.displayName[RoleConstants.leader] ?? 'Leader')
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: roleLabel == (RoleConstants.displayName[RoleConstants.leader] ?? 'Leader')
                                      ? Colors.orange[800]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(dateText, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $shortId...',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400], fontFamily: 'monospace'),
                        ),
                        if (trip.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            trip.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onManageMembers != null)
                    TextButton.icon(
                      key: memberBtnKey,
                      icon: const Icon(Icons.people, size: 18),
                      label: const Text('成員'),
                      onPressed: onManageMembers,
                    ),
                  if (onEdit != null)
                    TextButton.icon(icon: const Icon(Icons.edit, size: 18), label: const Text('編輯'), onPressed: onEdit),
                  if (onUpload != null) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('上傳'),
                      onPressed: onUpload,
                    ),
                  ],
                  if (onDelete != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('刪除'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
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
    return AlertDialog(
      title: Text(isEditing ? '編輯行程' : '新增行程'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '行程名稱',
                  hintText: '例如：2024 嘉明湖三日',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入行程名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 開始日期
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('開始日期'),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                onTap: () => _selectDate(isStartDate: true),
              ),
              // 結束日期
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('結束日期'),
                subtitle: Text(_endDate != null ? DateFormat('yyyy/MM/dd').format(_endDate!) : '未設定 (單日行程)'),
                trailing: _endDate != null
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _endDate = null))
                    : null,
                onTap: () => _selectDate(isStartDate: false),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '備註 (選填)',
                  hintText: '行程描述或備忘',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          'Trip ID: ${widget.tripToEdit!.id}',
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey),
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
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? '儲存' : '建立'),
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
