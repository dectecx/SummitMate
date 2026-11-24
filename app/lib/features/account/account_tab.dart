import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/auth_state.dart';
import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../shared/auth_messages.dart';
import '../../shared/sync_status_text.dart';

/// "我": account, sync status and app settings.
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value ?? ref.watch(authRepositoryProvider).state;
    return Scaffold(
      appBar: AppBar(title: const Text('我')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          switch (auth) {
            Guest() => const _GuestCard(),
            SignedIn(:final user) => _ProfileCard(user: user),
            NeedsReauth(:final user) => _ReauthCard(user: user),
          },
          const _SyncTile(),
          const Divider(height: 32),
          const _ThemeTile(),
          ListTile(leading: const Icon(Icons.group_outlined), title: const Text('好友'), onTap: () => context.push(Routes.friends)),
          ListTile(leading: const Icon(Icons.favorite_border), title: const Text('我的收藏'), onTap: () => context.push(Routes.favorites)),
          ListTile(leading: const Icon(Icons.bookmark_outline), title: const Text('我的裝備庫'), onTap: () => context.push(Routes.library)),
          ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('我的範本'), onTap: () => context.push(Routes.templates)),
          ListTile(leading: const Icon(Icons.cloud_outlined), title: const Text('雲端裝備組合'), onTap: () => context.push(Routes.sharedSets)),
          ListTile(leading: const Icon(Icons.help_outline), title: const Text('使用說明'), onTap: () => context.push(Routes.help)),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('重新顯示新手提示'),
            onTap: () async {
              await ref.read(settingsStoreProvider).resetHints();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提示會再次出現')));
            },
          ),
          if (auth is! Guest) ...[
            const Divider(height: 32),
            if (auth is SignedIn) ListTile(leading: const Icon(Icons.password), title: const Text('變更密碼'), onTap: () => _changePassword(context, ref)),
            ListTile(leading: const Icon(Icons.logout), title: const Text('登出'), onTap: () => _logout(context, ref)),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('刪除帳號', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => _deleteAccount(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('訪客模式', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('目前的資料只存在這支手機。登入後會自動備份，也能邀請隊友一起規劃。'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.me})), child: const Text('登入或註冊')),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      leading: CircleAvatar(radius: 28, child: Text(user.avatar, style: const TextStyle(fontSize: 28))),
      title: Text(user.displayName, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(user.email),
    );
  }
}

class _ReauthCard extends StatelessWidget {
  const _ReauthCard({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('登入已過期', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onErrorContainer)),
            const SizedBox(height: 4),
            Text('你仍然可以使用 App，但變更要重新登入後才會同步。\n${user.email}', style: TextStyle(color: scheme.onErrorContainer)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.me, 'email': user.email})),
              child: const Text('重新登入'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncTile extends ConsumerWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = describeSyncStatus(ref.watch(syncStatusProvider));
    return ListTile(
      leading: Icon(d.icon),
      title: Text(d.title),
      subtitle: d.detail == null ? null : Text(d.detail!),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('外觀'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('跟隨系統')),
            ButtonSegment(value: ThemeMode.light, label: Text('淺色')),
            ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
          ],
          selected: {mode},
          onSelectionChanged: (s) => ref.read(settingsStoreProvider).set(SettingsStore.themeMode, s.first.name),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ actions

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(authRepositoryProvider);
  try {
    final ok = await _confirm(context, title: '登出？', message: '登出後，這支手機上的行程資料會被清除（資料仍保存在雲端）。', action: '登出');
    if (ok != true) return;
    await repo.logout();
  } on UnsyncedChangesException catch (e) {
    if (!context.mounted) return;
    final force = await _confirm(
      context,
      title: '還有 ${e.count} 筆變更沒有上傳',
      message: '現在登出，這些變更會永久遺失。建議先連上網路、等同步完成再登出。',
      action: '仍要登出',
      destructive: true,
    );
    if (force == true) await repo.logout(force: true);
  }
}

Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
  final ok = await _confirm(
    context,
    title: '刪除帳號？',
    message: '帳號會被停用並登出，這個動作無法復原。',
    action: '刪除帳號',
    destructive: true,
  );
  if (ok != true) return;
  try {
    await ref.read(authRepositoryProvider).deleteAccount();
  } on Object catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
  }
}

Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
  final current = TextEditingController();
  final next = TextEditingController();
  final form = GlobalKey<FormState>();
  String? error;
  final done = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('變更密碼'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: '目前的密碼'), validator: (v) => (v ?? '').isEmpty ? '請輸入目前的密碼' : null),
              const SizedBox(height: 12),
              TextFormField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: '新密碼'), validator: validateNewPassword),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              try {
                await ref.read(authRepositoryProvider).changePassword(current: current.text, next: next.text);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on Object catch (e) {
                setState(() => error = authErrorMessage(e));
              }
            },
            child: const Text('變更'),
          ),
        ],
      ),
    ),
  );
  current.dispose();
  next.dispose();
  if (done == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密碼已變更')));
  }
}

Future<bool?> _confirm(BuildContext context, {required String title, required String message, required String action, bool destructive = false}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 44),
            backgroundColor: destructive ? Theme.of(ctx).colorScheme.error : null,
            foregroundColor: destructive ? Theme.of(ctx).colorScheme.onError : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
}
