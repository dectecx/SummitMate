import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di.dart';
import '../../core/error/result.dart';
import '../../core/constants/role_constants.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../../infrastructure/tools/log_service.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../../infrastructure/tools/toast_service.dart';
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

enum SearchType { email, id }

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final _tripRepository = getIt<ITripRepository>();
  // final _permissionService = getIt<PermissionService>(); // Removed as we use local list logic

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
    try {
      final result = await _tripRepository.updateMemberRole(widget.trip.id, userId, newRole);
      if (result is Failure) throw result.exception;

      final roleName = _getRoleName(newRole);
      ToastService.success('已將 $userName 更新為 $roleName');
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
      final result = await _tripRepository.removeMember(widget.trip.id, userId);
      if (result is Failure) throw result.exception;

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
    String currentRole = member['role_code'] ?? RoleConstants.member;
    // UI Selection State: default to member if current is not guide/member (e.g. is leader?)
    // If setting a Leader, we shouldn't happen here normally unless editing a Leader?
    // But we are editing *another* member.
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

  /// 顯示新增成員對話框 (搜尋 -> 確認)
  void _showSearchAddMemberDialog() {
    final queryController = TextEditingController();

    // Dialog 內部狀態
    bool localLoading = false;
    String? errorMsg;
    Map<String, dynamic>? searchResult;
    SearchType searchType = SearchType.email;

    // Confirmation State
    String selectedRole = RoleConstants.member;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Validation Checks
            final isSelf = searchResult != null && searchResult!['id'] == _currentUserId;
            // Check if already a member
            final isAlreadyMember = searchResult != null && _members.any((m) => m['id'] == searchResult!['id']);
            final canAdd = searchResult != null && !isSelf && !isAlreadyMember;

            return AlertDialog(
              title: const Text('新增成員'),
              content: SizedBox(
                width: 400, // Slightly wider
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (searchResult == null) ...[
                      // --- Stage 1: Search ---
                      const Text('搜尋方式', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<SearchType>(
                        segments: const [
                          ButtonSegment<SearchType>(
                            value: SearchType.email,
                            label: Text('Email'),
                            icon: Icon(Icons.email_outlined),
                          ),
                          ButtonSegment<SearchType>(
                            value: SearchType.id,
                            label: Text('User ID'),
                            icon: Icon(Icons.badge_outlined),
                          ),
                        ],
                        selected: {searchType},
                        onSelectionChanged: (Set<SearchType> newSelection) {
                          setState(() {
                            searchType = newSelection.first;
                            errorMsg = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: queryController,
                        decoration: InputDecoration(
                          labelText: searchType == SearchType.email ? '輸入使用者 Email' : '輸入 User ID',
                          hintText: searchType == SearchType.email ? 'example@gmail.com' : '使用者 UUID',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          errorText: errorMsg,
                          isDense: true,
                        ),
                        key: TutorialKeys.memberSearchInput,
                        onSubmitted: (_) {
                          // Trigger search
                        },
                      ),
                    ] else ...[
                      // --- Stage 2: Confirmation ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(searchResult!['avatar'] ?? ''),
                              onBackgroundImageError: (_, __) {},
                              child: Text(searchResult!['display_name']?[0] ?? '?'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    searchResult!['display_name'] ?? '未知用戶',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    searchResult!['email'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${searchResult!['id']}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isSelf)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('這是你自己，已在行程中。', style: TextStyle(color: Colors.brown)),
                              ),
                            ],
                          ),
                        )
                      else if (isAlreadyMember)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('此使用者已經是成員。', style: TextStyle(color: Colors.blueAccent)),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const Text('初始權限', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: RoleConstants.member,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_getRoleName(RoleConstants.member)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: RoleConstants.guide,
                              child: Row(
                                children: [
                                  const Icon(Icons.hiking, size: 18, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(_getRoleName(RoleConstants.guide)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedRole = val);
                          },
                        ),
                      ],

                      if (localLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(child: LinearProgressIndicator()),
                        ),

                      if (errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (searchResult == null) ...[
                  TextButton(onPressed: localLoading ? null : () => Navigator.pop(ctx), child: const Text('取消')),
                  FilledButton(
                    onPressed: localLoading
                        ? null
                        : () async {
                            final query = queryController.text.trim();
                            if (query.isEmpty) return;

                            setState(() {
                              localLoading = true;
                              errorMsg = null;
                            });

                            try {
                              // Split Search Logic
                              final UserProfile user;
                              final Result<UserProfile, Exception> result;
                              if (searchType == SearchType.email) {
                                result = await _tripRepository.searchUserByEmail(query);
                              } else {
                                result = await _tripRepository.searchUserById(query);
                              }

                              user = switch (result) {
                                Success(value: final u) => u,
                                Failure(exception: final e) => throw e,
                              };

                              if (mounted) {
                                setState(() {
                                  // Convert AppUser to Map for consistency with existing UI usage
                                  // Ideally UI should use AppUser model but keeping map for now
                                  searchResult = {
                                    'id': user.id,
                                    'display_name': user.displayName,
                                    'email': user.email,
                                    'avatar': user.avatar,
                                  };
                                  localLoading = false;
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  localLoading = false;
                                  errorMsg = e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            }
                          },
                    key: TutorialKeys.memberSearchBtn,
                    child: const Text('搜尋'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: localLoading
                        ? null
                        : () {
                            setState(() {
                              searchResult = null;
                              errorMsg = null;
                              queryController.clear();
                            });
                          },
                    child: const Text('重搜'),
                  ),
                  if (canAdd)
                    FilledButton(
                      onPressed: localLoading
                          ? null
                          : () async {
                              setState(() => localLoading = true);
                              try {
                                final userId = searchResult!['id'];
                                final Result<void, Exception> result;
                                if (searchType == SearchType.email) {
                                  // Use ID to add for safer reference
                                  result = await _tripRepository.addMemberById(
                                    widget.trip.id,
                                    userId,
                                    role: selectedRole,
                                  );
                                } else {
                                  result = await _tripRepository.addMemberById(
                                    widget.trip.id,
                                    userId,
                                    role: selectedRole,
                                  );
                                }
                                if (result is Failure) throw result.exception;

                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ToastService.success('已新增成員: ${searchResult!['display_name']}');
                                  _loadMembers();
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    localLoading = false;
                                    errorMsg = '新增失敗: ${e.toString().replaceAll('Exception: ', '')}';
                                  });
                                }
                              }
                            },
                      key: TutorialKeys.memberConfirmBtn,
                      child: const Text('確認加入'),
                    ),
                ],
              ],
            );
          },
        );
      },
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
    // We only rely on _currentUserId which we set in initState, but let's keep it reactive if user swaps
    if (authState is AuthAuthenticated) {
      if (_currentUserId != authState.userId) _currentUserId = authState.userId;
    }

    // Determine permissions based on Trip Data & Member List
    final isOwner = widget.trip.userId == _currentUserId;

    // Find my role in the loaded list
    // If list is empty (loading or error), we assume NO permission unless owner
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
      appBar: AppBar(
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
                final roleCode = member['role_code'] ?? 'member';
                final isSelf = member['id'] == _currentUserId;
                final isRowOwner = member['id'] == widget.trip.userId; // Check who is the trip owner row

                // Determine role style
                String roleText = _getRoleName(roleCode);
                IconData roleIcon = Icons.person_outline;
                Color? roleColor;

                if (roleCode == RoleConstants.admin || roleCode == RoleConstants.leader || isRowOwner) {
                  roleText = _getRoleName(RoleConstants.leader); // Strictly Chinese as requested
                  if (isRowOwner) roleText += ' (擁)';

                  roleIcon = Icons.stars;
                  roleColor = Colors.amber;
                } else if (roleCode == RoleConstants.guide) {
                  roleText = _getRoleName(RoleConstants.guide);
                  roleIcon = Icons.hiking;
                  roleColor = Colors.green;
                } else {
                  roleText = _getRoleName(RoleConstants.member);
                }

                // Can edit this row?
                // Only if current user canManage, target is NOT self, and target is NOT owner
                // We cannot edit the Owner (even if we are Leader)
                // We cannot edit ourselves here (use different flow if needed, but usually 'Leave Trip')
                final canEditRow = canManage && !isSelf && !isRowOwner;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(member['avatar'] ?? ''),
                    onBackgroundImageError: (_, __) {},
                    child: (member['avatar'] == null || member['avatar'].isEmpty)
                        ? Text(member['display_name']?[0] ?? '?')
                        : null,
                  ),
                  title: Text(member['display_name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(roleIcon, size: 16, color: roleColor),
                          const SizedBox(width: 4),
                          Text(
                            roleText,
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text('ID: ${member['id'] ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
