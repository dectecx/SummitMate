import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di.dart';
import 'package:summitmate/core/core.dart';

import '../../data/models/trip.dart';
import '../../data/models/enums/sync_status.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../widgets/common/summit_app_bar.dart';
import '../widgets/member/search_add_member_dialog.dart';
import '../widgets/member/member_list_tile.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';

import '../utils/tutorial_keys.dart';

/// 成員管理畫面
///
/// 顯示行程成員列表，並允許具有權限的使用者（團長/管理員）管理成員權限。
class MemberManagementScreen extends StatefulWidget {
  /// 當前行程物件
  final Trip trip;

  const MemberManagementScreen({super.key, required this.trip});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final _tripRepository = getIt<ITripRepository>();

  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = (context.read<AuthCubit>().state as AuthAuthenticated).userId;
    _loadMembers();
  }

  /// 載入成員列表
  ///
  /// 從遠端資料來源取得最新的成員名單與權限狀態。
  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    // [Local First] If trip is not synced (pendingCreate), use local data (Creator only)
    if (widget.trip.syncStatus == SyncStatus.pendingCreate) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        // Verify if current user is indeed the creator/owner (should be for pendingCreate)
        if (widget.trip.userId == user.id || widget.trip.members.contains(user.id)) {
          final localMember = {
            'id': user.id,
            'display_name': user.displayName,
            'email': user.email,
            'avatar': user.avatar,
            'role_code': RoleConstants.leader, // Creator is Leader
          };

          setState(() {
            _members = [localMember];
            _isLoading = false;
          });
          return;
        }
      }
    }

    try {
      final result = await _tripRepository.getTripMembers(widget.trip.id);
      final members = switch (result) {
        Success(value: final m) => m,
        Failure(exception: final e) => throw e,
      };

      // 異常狀態檢查：若無成員 (理論上不應發生)
      if (members.isEmpty) {
        LogService.error('Trip ${widget.trip.id} has no members!', source: 'MemberManagementScreen');
      }

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastService.error('無法載入成員列表: $e');
    }
  }

  /// 更新成員角色
  ///
  /// [userId] 目標成員 ID
  /// [newRole] 新角色代碼 (e.g., guide, member)
  /// [userName] 成員顯示名稱 (用於顯示 Toast)
  Future<void> _updateRole(String userId, String newRole, String userName) async {
    final result = await _tripRepository.updateMemberRole(widget.trip.id, userId, newRole);
    if (result is Failure) {
      ToastService.error('權限更新失敗: ${result.exception}');
      return;
    }
    ToastService.success('已更新 $userName 的權限');
    _loadMembers();
  }

  /// 移除成員
  ///
  /// [userId] 目標成員 ID
  /// [userName] 成員顯示名稱 (用於顯示 Toast)
  Future<void> _removeMember(String userId, String userName) async {
    final result = await _tripRepository.removeMember(widget.trip.id, userId);
    if (result is Failure) {
      ToastService.error('移除失敗: ${result.exception}');
      return;
    }
    ToastService.success('已移除 $userName');
    _loadMembers();
  }

  /// 顯示權限設定對話框
  ///
  /// [member] 成員資料 Map (包含 id, display_name, role_code 等)
  void _showRoleDialog(Map<String, dynamic> member) {
    String currentRole = member['role_code'] ?? RoleConstants.member;
    String selectedRole = (currentRole == RoleConstants.guide) ? RoleConstants.guide : RoleConstants.member;

    final isTargetLeader = currentRole == RoleConstants.leader || currentRole == RoleConstants.admin;
    final isCurrentUserOwner = widget.trip.userId == _currentUserId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('設定 ${member['display_name']} 的權限'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isTargetLeader) ...[
                    RadioListTile<String>(
                      title: Text(_getRoleName(RoleConstants.guide)),
                      subtitle: const Text('可編輯行程、管理公裝'),
                      value: RoleConstants.guide,
                      groupValue: selectedRole,
                      onChanged: (val) => setDialogState(() => selectedRole = val!),
                    ),
                    RadioListTile<String>(
                      title: Text(_getRoleName(RoleConstants.member)),
                      subtitle: const Text('僅檢視行程、編輯個人裝備'),
                      value: RoleConstants.member,
                      groupValue: selectedRole,
                      onChanged: (val) => setDialogState(() => selectedRole = val!),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('此成員為團長，請使用移轉功能或移除。', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                  if (isCurrentUserOwner && !isTargetLeader) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.stars, color: Colors.amber),
                      title: const Text('移轉團長身分'),
                      subtitle: const Text('將團長權限移轉給此成員'),
                      onTap: () {
                        Navigator.pop(context);
                        _confirmTransferLeader(member);
                      },
                    ),
                  ],
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('移出行程', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmRemove(member);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                if (!isTargetLeader)
                  FilledButton(
                    onPressed: () {
                      if (selectedRole != currentRole) {
                        Navigator.pop(context);
                        _updateRole(member['id'], selectedRole, member['display_name']);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('儲存'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// 顯示移轉團長確認對話框
  void _confirmTransferLeader(Map<String, dynamic> targetMember) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移轉團長身分'),
        content: Text('確定要將團長身分移轉給 ${targetMember['display_name']} 嗎？\n\n移轉後，您將變更為「成員」，且無法再管理行程成員。此操作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                // 1. Promote Target to Leader
                final r1 = await _tripRepository.updateMemberRole(
                  widget.trip.id,
                  targetMember['id'],
                  RoleConstants.leader,
                );
                if (r1 is Failure) throw r1.exception;

                // 2. Demote Self to Member
                final r2 = await _tripRepository.updateMemberRole(
                  widget.trip.id,
                  _currentUserId!,
                  RoleConstants.member,
                );
                if (r2 is Failure) throw r2.exception;

                ToastService.success('已移轉團長身分給 ${targetMember['display_name']}');
                _loadMembers();
              } catch (e) {
                setState(() => _isLoading = false);
                ToastService.error('移轉失敗: $e');
              }
            },
            child: const Text('確認移轉', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  /// 顯示移除成員確認對話框
  ///
  /// [member] 成員資料 Map
  void _confirmRemove(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除成員'),
        content: Text('確定要將 ${member['display_name']} 移出此行程嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMember(member['id'], member['display_name']);
            },
            child: const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 顯示新增成員對話框
  void _showSearchAddMemberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SearchAddMemberDialog(
        tripId: widget.trip.id,
        tripRepository: _tripRepository,
        currentUserId: _currentUserId!,
        existingMemberIds: _members.map((m) => m['id'] as String).toList(),
        onMemberAdded: _loadMembers,
      ),
    );
  }

  /// Helper to get localized role name
  String _getRoleName(String code) {
    return RoleConstants.displayName[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    // Current user profile for checking ID
    final authState = context.watch<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (_currentUserId != authState.userId) _currentUserId = authState.userId;
    }

    // Determine permissions based on Trip Data & Member List
    final isOwner = widget.trip.userId == _currentUserId;

    // Find my role in the loaded list
    String myRole = RoleConstants.member;
    if (_members.isNotEmpty && _currentUserId != null) {
      try {
        final me = _members.firstWhere((m) => m['id'] == _currentUserId);
        myRole = me['role_code'] ?? RoleConstants.member;
      } catch (_) {
        // Not in list
      }
    }

    // Permission Logic: Owner OR Leader
    final canManage = isOwner || myRole == RoleConstants.leader || myRole == RoleConstants.admin;

    return Scaffold(
      appBar: SummitAppBar(
        title: const Text('成員管理'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMembers)],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _showSearchAddMemberDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('新增成員'),
              key: TutorialKeys.memberFab,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('無成員', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  TextButton.icon(onPressed: _loadMembers, icon: const Icon(Icons.refresh), label: const Text('重新載入')),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final isSelf = member['id'] == _currentUserId;
                final isRowOwner = member['id'] == widget.trip.userId;

                // Can edit this row?
                final canEditRow = canManage && !isSelf && !isRowOwner;

                return MemberListTile(
                  member: member,
                  isSelf: isSelf,
                  isOwner: isRowOwner,
                  canEdit: canEditRow,
                  onSettingsTap: () => _showRoleDialog(member),
                );
              },
            ),
    );
  }
}
