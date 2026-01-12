import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di.dart';
import '../../core/services/permission_service.dart';
import '../../core/constants/role_constants.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../../infrastructure/tools/toast_service.dart';

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
  final _permissionService = getIt<PermissionService>();

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
    try {
      final members = await _tripRepository.getTripMembers(widget.trip.id);
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
    try {
      await _tripRepository.updateMemberRole(widget.trip.id, userId, newRole);
      ToastService.success('已將 $userName 更新為 $newRole');
      _loadMembers();
    } catch (e) {
      ToastService.error('更新失敗: $e');
    }
  }

  /// 移除成員
  ///
  /// [userId] 目標成員 ID
  /// [userName] 成員顯示名稱 (用於顯示 Toast)
  Future<void> _removeMember(String userId, String userName) async {
    try {
      await _tripRepository.removeMember(widget.trip.id, userId);
      ToastService.success('已移除 $userName');
      _loadMembers();
    } catch (e) {
      ToastService.error('移除失敗: $e');
    }
  }

  /// 顯示權限設定對話框
  ///
  /// [member] 成員資料 Map (包含 id, display_name, role_code 等)
  void _showRoleDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Simple dialog for now
          title: Text('設定 ${member['display_name']} 的權限'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('嚮導 (Guide)'),
                subtitle: const Text('可編輯行程、管理公裝'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRole(member['id'], RoleConstants.guide, member['display_name']);
                },
              ),
              ListTile(
                title: const Text('成員 (Member)'),
                subtitle: const Text('僅檢視行程、編輯個人裝備'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRole(member['id'], RoleConstants.member, member['display_name']);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('移出行程', style: TextStyle(color: Colors.red)),
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemove(member);
                },
              ),
            ],
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    // Current user profile for permission check
    final authState = context.watch<AuthCubit>().state;
    final currentUser = (authState is AuthAuthenticated) ? authState.user : null;

    // Check if current user can manage members
    final canManage = _permissionService.canManageMembersSync(currentUser, widget.trip);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成員管理'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMembers)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final roleCode = member['role_code'] ?? 'member';
                final isSelf = member['id'] == _currentUserId;
                final isOwner = member['id'] == widget.trip.userId; // Assuming trip.userId is owner

                // Determine role display
                String roleText = '成員';
                IconData roleIcon = Icons.person_outline;
                Color? roleColor;

                if (roleCode == RoleConstants.admin || roleCode == RoleConstants.leader || isOwner) {
                  // Owner implies leader usually
                  roleText = '團長 (Leader)';
                  roleIcon = Icons.stars;
                  roleColor = Colors.amber;
                } else if (roleCode == RoleConstants.guide) {
                  roleText = '嚮導 (Guide)';
                  roleIcon = Icons.hiking;
                  roleColor = Colors.green;
                }

                // Can edit this row?
                // Only if current user canManage, target is NOT self, and target is NOT owner
                final canEditRow = canManage && !isSelf && !isOwner;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(member['avatar'] ?? ''),
                    onBackgroundImageError: (_, __) {},
                    child: (member['avatar'] == null || member['avatar'].isEmpty)
                        ? Text(member['display_name']?[0] ?? '?')
                        : null,
                  ),
                  title: Text(member['display_name'] ?? 'Unknown'),
                  subtitle: Row(
                    children: [
                      Icon(roleIcon, size: 16, color: roleColor),
                      const SizedBox(width: 4),
                      Text(
                        roleText,
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: canEditRow
                      ? OutlinedButton(onPressed: () => _showRoleDialog(member), child: const Text('設定'))
                      : null,
                );
              },
            ),
    );
  }
}
