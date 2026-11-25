import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/auth_messages.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/settings_section.dart';
import '../../members/domain/member_logic.dart';
import '../../members/providers.dart';
import '../../trips/providers.dart';
import '../data/friends_api.dart';
import '../providers.dart';
import '../../../shared/brand/illustrations.dart';
import '../../../shared/form_sheet.dart';

/// "好友": my friends, requests waiting for my answer, and requests I sent. Needs sign-in and a connection.
class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(accountIdProvider) != null;
    return Scaffold(
      appBar: AppBar(title: const Text('好友')),
      floatingActionButton: signedIn
          ? FloatingActionButton.extended(
              key: const ValueKey('add-friend'),
              onPressed: () => showAddFriendSheet(context),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('加好友'),
            )
          : null,
      body: !signedIn
          ? const ComingSoon(illustration: Illustration.friends, message: '登入後，就能加好友，邀請隊友時直接從好友名單挑選，不用再記 Email。')
          : ref
                .watch(friendsProvider)
                .when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _Retry(error: e, onRetry: () => ref.invalidate(friendsProvider)),
                  data: (o) => RefreshIndicator(
                    onRefresh: () => ref.refresh(friendsProvider.future),
                    child: _Lists(overview: o),
                  ),
                ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ComingSoon(
    icon: Icons.cloud_off_outlined,
    message: error is FriendsException ? (error as FriendsException).text : '載入失敗，請稍後再試。',
    action: OutlinedButton(onPressed: onRetry, child: const Text('重試')),
  );
}

class _Lists extends ConsumerWidget {
  const _Lists({required this.overview});
  final FriendsOverview overview;

  Future<void> _do(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(friendsProvider);
    } on FriendsException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.text)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(friendsApiProvider);
    final theme = Theme.of(context);
    if (overview.friends.isEmpty && overview.incoming.isEmpty && overview.outgoing.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          ComingSoon(illustration: Illustration.friends, message: '還沒有好友。點「加好友」，輸入對方的 Email 送出邀請，對方接受後才會成為好友。'),
        ],
      );
    }
    Widget avatar(Friend f) => Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(f.avatar.isEmpty ? '🙂' : f.avatar, style: const TextStyle(fontSize: 20)),
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (overview.incoming.isNotEmpty)
          SettingsSection(
            title: '好友邀請（${overview.incoming.length}）',
            children: [
              for (final r in overview.incoming)
                ListTile(
                  key: ValueKey('incoming-${r.user.userId}'),
                  shape: const RoundedRectangleBorder(),
                  leading: avatar(r.user),
                  title: Text(r.user.displayName),
                  subtitle: const Text('想加你為好友'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '拒絕',
                        icon: const Icon(Icons.close),
                        onPressed: () => _do(context, ref, () => api.dismiss(r.id)),
                      ),
                      IconButton.filled(
                        tooltip: '接受',
                        // A list row would otherwise paint the tick in its own grey, invisible on the filled circle.
                        style: IconButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary, backgroundColor: theme.colorScheme.primary),
                        icon: const Icon(Icons.check),
                        onPressed: () => _do(context, ref, () => api.accept(r.id)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (overview.outgoing.isNotEmpty)
          SettingsSection(
            title: '已送出的邀請',
            children: [
              for (final r in overview.outgoing)
                ListTile(
                  key: ValueKey('outgoing-${r.user.userId}'),
                  shape: const RoundedRectangleBorder(),
                  leading: avatar(r.user),
                  title: Text(r.user.displayName),
                  subtitle: const Text('等待對方接受'),
                  trailing: TextButton(
                    onPressed: () => _do(context, ref, () => api.dismiss(r.id)),
                    child: const Text('收回'),
                  ),
                ),
            ],
          ),
        SettingsSection(
          title: '好友（${overview.friends.length}）',
          children: [
            if (overview.friends.isEmpty) const ListTile(shape: RoundedRectangleBorder(), title: Text('還沒有好友')),
            for (final f in overview.friends)
              ListTile(
                key: ValueKey('friend-${f.userId}'),
                shape: const RoundedRectangleBorder(),
                leading: avatar(f),
                title: Text(f.displayName),
                trailing: PopupMenuButton<String>(
                  tooltip: '管理 ${f.displayName}',
                  onSelected: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('移除好友 ${f.displayName}？'),
                        content: const Text('對方不會收到通知。之後想再加，需要重新送出邀請。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('移除')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) await _do(context, ref, () => api.unfriend(f.userId));
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('移除好友'))],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Sends a friend request to the person with this exact e-mail.
Future<void> showAddFriendSheet(BuildContext context) => showFormSheet<void>(
    context: context,
    builder: (_) => const AddFriendSheet(),
);

class AddFriendSheet extends ConsumerStatefulWidget {
  const AddFriendSheet({super.key});

  @override
  ConsumerState<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<AddFriendSheet> {
  final _email = TextEditingController();
  FoundUser? _found;
  String? _message;
  bool _busy = false;

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
      final overview = await ref.read(friendsProvider.future);
      if (!mounted) return;
      setState(() {
        if (users.isEmpty) {
          _message = '找不到這個 Email 的使用者。對方需要先註冊並完成信箱驗證。';
        } else if (users.first.id == ref.read(accountIdProvider)) {
          _message = '這是你自己的 Email。';
        } else if (overview.isFriend(users.first.id)) {
          _message = '${users.first.displayName} 已經是你的好友了。';
        } else if (overview.hasOutgoingTo(users.first.id)) {
          _message = '已經送出邀請給 ${users.first.displayName}，等對方接受。';
        } else {
          _found = users.first;
        }
      });
    } on Object catch (e) {
      if (mounted) setState(() => _message = e is FriendsException ? e.text : authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final user = _found;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(friendsApiProvider).sendRequest(user.id);
      ref.invalidate(friendsProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == FriendRequestResult.accepted ? '你和 ${user.displayName} 成為好友了' : '已送出邀請，等 ${user.displayName} 接受',
          ),
        ),
      );
    } on FriendsException catch (e) {
      if (mounted) setState(() => _message = e.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            Text('加好友', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('friend-email'),
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: '對方的 Email',
                suffixIcon: IconButton(
                  tooltip: '搜尋',
                  icon: const Icon(Icons.search),
                  onPressed: _busy ? null : _search,
                ),
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_found != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(_found!.avatar),
                  ),
                  title: Text(_found!.displayName),
                  subtitle: const Text('找到了'),
                ),
              ),
              FilledButton(
                key: const ValueKey('send-friend-request'),
                onPressed: _busy ? null : _send,
                child: Text('送出好友邀請給 ${_found!.displayName}'),
              ),
              const SizedBox(height: 8),
              Text(
                '對方接受後才會成為好友。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
