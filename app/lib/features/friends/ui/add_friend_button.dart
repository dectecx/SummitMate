import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../trips/providers.dart';
import '../data/friends_api.dart';
import '../providers.dart';

/// A small "add friend" control next to a person met in a group event. It disappears for yourself, for
/// guests, for people already your friends, and says "已邀請" while a request is waiting.
class AddFriendButton extends ConsumerWidget {
  const AddFriendButton({super.key, required this.userId, required this.name});

  /// The person's account id; empty when the server did not give one.
  final String userId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(accountIdProvider);
    if (me == null || userId.isEmpty || userId == me) return const SizedBox.shrink();
    final overview = ref.watch(friendsProvider).value;
    if (overview == null || overview.isFriend(userId)) return const SizedBox.shrink();
    if (overview.hasOutgoingTo(userId)) {
      return Text('已邀請', key: ValueKey('friend-pending-$userId'), style: Theme.of(context).textTheme.labelSmall);
    }
    return IconButton(
      key: ValueKey('add-friend-$userId'),
      tooltip: overview.hasIncomingFrom(userId) ? '接受 $name 的好友邀請' : '加 $name 為好友',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.person_add_alt, size: 20),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          final result = await ref.read(friendsApiProvider).sendRequest(userId);
          ref.invalidate(friendsProvider);
          messenger.showSnackBar(
            SnackBar(content: Text(result == FriendRequestResult.accepted ? '你和 $name 成為好友了' : '已送出邀請，等 $name 接受')),
          );
        } on FriendsException catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(e.text)));
        }
      },
    );
  }
}
