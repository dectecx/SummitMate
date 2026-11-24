import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/auth/auth_api.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../trips/domain/trip_logic.dart';
import '../domain/member_logic.dart';
import '../providers.dart';
import 'invite_sheet.dart';

/// "成員": who is on the trip, who may do what, and the forecast.
class MembersView extends ConsumerWidget {
  const MembersView({super.key, required this.trip, required this.role});
  final Trip trip;
  final TripRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(memberLinesProvider(trip.id));
    final auth = ref.watch(authStateProvider).value ?? ref.watch(authRepositoryProvider).state;
    final signedIn = auth is SignedIn;
    final isGuest = auth is Guest;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Expanded(child: Text('成員（${lines.length}）', style: theme.textTheme.titleMedium)),
              if (signedIn && canInvite(role))
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => showInviteSheet(context, tripId: trip.id, existingUserIds: {for (final l in lines) l.userId}),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('邀請'),
                ),
            ],
          ),
        ),
        if (isGuest)
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('登入後才能邀請隊友一起規劃，行程也會自動備份。'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.trip(trip.id)})),
                    child: const Text('登入或註冊'),
                  ),
                ],
              ),
            ),
          ),
        for (final line in lines) _MemberTile(trip: trip, line: line, myRole: role),
        if (signedIn && role != TripRole.owner && lines.any((l) => l.isMe))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _leave(context, ref, trip, lines.firstWhere((l) => l.isMe).userId),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('離開這個行程'),
            ),
          ),
      ],
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.trip, required this.line, required this.myRole});
  final Trip trip;
  final MemberLine line;
  final TripRole myRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manage = canManageMember(me: myRole, target: line.role);
    return ListTile(
      leading: CircleAvatar(child: Text(line.avatar)),
      title: Text(line.isMe ? '${line.displayName}（你）' : line.displayName),
      subtitle: Text(line.role.label),
      trailing: manage
          ? PopupMenuButton<String>(
              tooltip: '管理 ${line.displayName}',
              onSelected: (v) async {
                final repo = ref.read(memberRepositoryProvider);
                switch (v) {
                  case 'guide' || 'member':
                    await repo.setRole(trip.id, line.userId, v);
                  case 'transfer':
                    await _transfer(context, ref, trip, line);
                  case 'remove':
                    final ok = await _confirm(context, title: '移除 ${line.displayName}？', message: '對方會失去這個行程，也看不到之後的更新。', action: '移除');
                    if (ok == true) await repo.remove(trip.id, line.userId);
                }
              },
              itemBuilder: (_) => [
                if (line.role != TripRole.guide && myRole == TripRole.owner) const PopupMenuItem(value: 'guide', child: Text('設為嚮導')),
                if (line.role != TripRole.member) const PopupMenuItem(value: 'member', child: Text('設為隊員')),
                if (myRole == TripRole.owner && ref.watch(authStateProvider).value is SignedIn) const PopupMenuItem(value: 'transfer', child: Text('移交團長')),
                const PopupMenuItem(value: 'remove', child: Text('移除成員')),
              ],
            )
          : null,
    );
  }
}

/// Online only: pushes pending changes first (the server must know the trip and the member), then hands over.
Future<void> _transfer(BuildContext context, WidgetRef ref, Trip trip, MemberLine to) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await _confirm(
    context,
    title: '把團長交給 ${to.displayName}？',
    message: '${to.displayName} 會成為團長，你會變成嚮導：仍可編輯行程，但不能刪除行程或移交團長。需要連上網路。',
    action: '移交',
  );
  if (ok != true) return;
  final sync = ref.read(syncCoordinatorProvider);
  try {
    await sync.refresh();
    await ref.read(tripOwnerApiProvider).transfer(trip.id, to.userId);
    await sync.refresh();
    messenger.showSnackBar(SnackBar(content: Text('已把團長交給 ${to.displayName}')));
  } on AuthNetworkException {
    messenger.showSnackBar(const SnackBar(content: Text('目前無法連線，移交團長需要網路。')));
  } on AuthException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message.isNotEmpty ? e.message : '移交失敗（${e.code}）')));
  }
}

Future<void> _leave(BuildContext context, WidgetRef ref, Trip trip, String myId) async {
  final ok = await _confirm(context, title: '離開「${trip.name}」？', message: '離開後這個行程會從你的手機移除，你的裝備與餐食規劃也會一併消失。', action: '離開');
  if (ok != true) return;
  await ref.read(memberRepositoryProvider).leave(trip.id, myId);
  if (context.mounted) context.pop();
}

Future<bool?> _confirm(BuildContext context, {required String title, required String message, required String action}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44), backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
}
