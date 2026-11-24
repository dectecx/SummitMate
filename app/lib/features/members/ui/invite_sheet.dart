import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/auth_messages.dart';
import '../domain/member_logic.dart';
import '../providers.dart';
import '../../friends/data/friends_api.dart';
import '../../friends/providers.dart';

/// Invite a registered person to the trip by e-mail.
Future<void> showInviteSheet(BuildContext context, {required String tripId, required Set<String> existingUserIds}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => InviteSheet(tripId: tripId, existingUserIds: existingUserIds),
  );
}

class InviteSheet extends ConsumerStatefulWidget {
  const InviteSheet({super.key, required this.tripId, required this.existingUserIds});
  final String tripId;
  final Set<String> existingUserIds;

  @override
  ConsumerState<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<InviteSheet> {
  final _email = TextEditingController();
  FoundUser? _found;
  String? _message;
  bool _busy = false;
  String _role = 'member';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _email.text.trim().toLowerCase();
    if (validateEmail(email) != null) {
      setState(() => _message = 'Email 格式不正確');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _found = null;
    });
    try {
      final users = await ref.read(userSearchApiProvider).findByEmail(email);
      if (!mounted) return;
      setState(() {
        if (users.isEmpty) {
          _message = '找不到這個 Email 的使用者。對方需要先註冊並完成信箱驗證。';
        } else if (widget.existingUserIds.contains(users.first.id)) {
          _message = '${users.first.displayName} 已經在這個行程裡了。';
        } else {
          _found = users.first;
        }
      });
    } on Object catch (e) {
      if (mounted) setState(() => _message = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final user = _found;
    if (user == null) return;
    await ref.read(memberRepositoryProvider).invite(widget.tripId, user, role: _role);
    if (mounted) Navigator.pop(context);
  }

  /// My friends who are not in the trip yet, to pick instead of typing an e-mail (empty when offline or no friends).
  List<Widget> _friendChoices(ThemeData theme) {
    final overview = ref.watch(friendsProvider).value;
    final candidates = [for (final f in overview?.friends ?? const <Friend>[]) if (!widget.existingUserIds.contains(f.userId)) f];
    if (candidates.isEmpty) return const [];
    return [
      Text('從好友挑選', style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: [
          for (final f in candidates)
            ChoiceChip(
              key: ValueKey('invite-friend-${f.userId}'),
              avatar: Text(f.avatar.isEmpty ? '🙂' : f.avatar),
              label: Text(f.displayName),
              selected: _found?.id == f.userId,
              onSelected: (_) => setState(() {
                _found = f.toFoundUser();
                _message = null;
              }),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text('或輸入 Email 邀請還不是好友的人', style: theme.textTheme.bodySmall),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('邀請成員', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._friendChoices(theme),
            const SizedBox(height: 4),
            TextField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: '對方的 Email',
                suffixIcon: IconButton(tooltip: '搜尋', icon: const Icon(Icons.search), onPressed: _busy ? null : _search),
              ),
            ),
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: TextStyle(color: theme.colorScheme.error))),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
            if (_found != null) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(_found!.avatar)),
                title: Text(_found!.displayName),
                subtitle: const Text('找到了'),
              ),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [ButtonSegment(value: 'member', label: Text('隊員')), ButtonSegment(value: 'guide', label: Text('嚮導'))],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 4),
              Text(_role == 'guide' ? '嚮導可以編輯行程節點與邀請隊員。' : '隊員可以查看行程，並規劃自己的裝備與餐食。', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(onPressed: _invite, child: Text('邀請 ${_found!.displayName}')),
            ],
          ],
        ),
      ),
    );
  }
}
