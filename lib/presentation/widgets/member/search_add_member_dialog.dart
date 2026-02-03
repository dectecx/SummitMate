import 'package:flutter/material.dart';
import 'package:summitmate/core/core.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../utils/tutorial_keys.dart';

/// 搜尋類型枚舉
enum SearchType { email, id }

/// 搜尋新增成員對話框
///
/// 提供 Email 或 User ID 搜尋使用者，確認後新增至行程成員列表。
///
/// [tripId] 目標行程 ID
/// [tripRepository] 行程資料庫介面
/// [currentUserId] 當前使用者 ID
/// [existingMemberIds] 已存在的成員 ID 列表
/// [onMemberAdded] 成功新增成員後的回調
class SearchAddMemberDialog extends StatefulWidget {
  /// 目標行程 ID
  final String tripId;

  /// 行程資料庫介面
  final ITripRepository tripRepository;

  /// 當前使用者 ID
  final String currentUserId;

  /// 已存在的成員 ID 列表
  final List<String> existingMemberIds;

  /// 成功新增成員後的回調
  final VoidCallback onMemberAdded;

  const SearchAddMemberDialog({
    super.key,
    required this.tripId,
    required this.tripRepository,
    required this.currentUserId,
    required this.existingMemberIds,
    required this.onMemberAdded,
  });

  @override
  State<SearchAddMemberDialog> createState() => _SearchAddMemberDialogState();
}

class _SearchAddMemberDialogState extends State<SearchAddMemberDialog> {
  final _queryController = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;
  Map<String, dynamic>? _searchResult;
  SearchType _searchType = SearchType.email;
  String _selectedRole = RoleConstants.member;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// 執行搜尋
  Future<void> _performSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final Result<UserProfile, Exception> result;
      if (_searchType == SearchType.email) {
        result = await widget.tripRepository.searchUserByEmail(query);
      } else {
        result = await widget.tripRepository.searchUserById(query);
      }

      final user = switch (result) {
        Success(value: final u) => u,
        Failure(exception: final e) => throw e,
      };

      if (mounted) {
        setState(() {
          _searchResult = {
            'id': user.id,
            'display_name': user.displayName,
            'email': user.email,
            'avatar': user.avatar,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// 新增成員
  Future<void> _addMember() async {
    if (_searchResult == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = _searchResult!['id'];
      final result = await widget.tripRepository.addMemberById(
        widget.tripId,
        userId,
        role: _selectedRole,
      );
      if (result is Failure) throw result.exception;

      if (mounted) {
        Navigator.pop(context);
        ToastService.success('已新增成員: ${_searchResult!['display_name']}');
        widget.onMemberAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '新增失敗: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  /// 重置搜尋
  void _resetSearch() {
    setState(() {
      _searchResult = null;
      _errorMsg = null;
      _queryController.clear();
    });
  }

  /// 取得本地化角色名稱
  String _getRoleName(String code) {
    return RoleConstants.displayName[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = _searchResult != null && _searchResult!['id'] == widget.currentUserId;
    final isAlreadyMember = _searchResult != null &&
        widget.existingMemberIds.contains(_searchResult!['id']);
    final canAdd = _searchResult != null && !isSelf && !isAlreadyMember;

    return AlertDialog(
      title: const Text('新增成員'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_searchResult == null) ...[
              // --- Stage 1: Search ---
              _buildSearchStage(),
            ] else ...[
              // --- Stage 2: Confirmation ---
              _buildConfirmationStage(isSelf, isAlreadyMember, canAdd),
            ],
          ],
        ),
      ),
      actions: _buildActions(canAdd),
    );
  }

  /// 建立搜尋階段 UI
  Widget _buildSearchStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          selected: {_searchType},
          onSelectionChanged: (Set<SearchType> newSelection) {
            setState(() {
              _searchType = newSelection.first;
              _errorMsg = null;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _queryController,
          decoration: InputDecoration(
            labelText: _searchType == SearchType.email ? '輸入使用者 Email' : '輸入 User ID',
            hintText: _searchType == SearchType.email ? 'example@gmail.com' : '使用者 UUID',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            errorText: _errorMsg,
            isDense: true,
          ),
          key: TutorialKeys.memberSearchInput,
          onSubmitted: (_) => _performSearch(),
        ),
      ],
    );
  }

  /// 建立確認階段 UI
  Widget _buildConfirmationStage(bool isSelf, bool isAlreadyMember, bool canAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User info card
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
                backgroundImage: NetworkImage(_searchResult!['avatar'] ?? ''),
                onBackgroundImageError: (_, _) {},
                child: Text(_searchResult!['display_name']?[0] ?? '?'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchResult!['display_name'] ?? '未知用戶',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _searchResult!['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${_searchResult!['id']}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Validation messages
        if (isSelf)
          _buildWarningBox(
            icon: Icons.warning_amber,
            color: Colors.amber,
            text: '這是你自己，已在行程中。',
            backgroundColor: Colors.amber[50]!,
          )
        else if (isAlreadyMember)
          _buildWarningBox(
            icon: Icons.info_outline,
            color: Colors.blue,
            text: '此使用者已經是成員。',
            backgroundColor: Colors.blue[50]!,
          )
        else ...[
          const Text('初始權限', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
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
              if (val != null) setState(() => _selectedRole = val);
            },
          ),
        ],

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: LinearProgressIndicator()),
          ),

        // Error message
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  /// 建立警告提示框
  Widget _buildWarningBox({
    required IconData icon,
    required Color color,
    required String text,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.brown))),
        ],
      ),
    );
  }

  /// 建立動作按鈕
  List<Widget> _buildActions(bool canAdd) {
    if (_searchResult == null) {
      return [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _performSearch,
          key: TutorialKeys.memberSearchBtn,
          child: const Text('搜尋'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: _isLoading ? null : _resetSearch,
          child: const Text('重搜'),
        ),
        if (canAdd)
          FilledButton(
            onPressed: _isLoading ? null : _addMember,
            key: TutorialKeys.memberConfirmBtn,
            child: const Text('確認加入'),
          ),
      ];
    }
  }
}
