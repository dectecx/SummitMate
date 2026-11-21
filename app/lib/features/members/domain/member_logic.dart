import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';

/// Namespace of the deterministic trip_members ids. Must equal the server's `memberNamespace`.
const memberNamespace = '6f1c2a52-6d3a-4f5e-9d9a-3b9d8c0a7e11';

/// The id of the membership row of [userId] in [tripId] (uuid v5, same rule as the server).
/// Re-inviting someone who was removed revives the same row instead of creating a second one.
String memberIdFor(String tripId, String userId) => const Uuid().v5(memberNamespace, '$tripId:$userId');

/// A person found by e-mail search.
class FoundUser {
  const FoundUser({required this.id, required this.displayName, required this.avatar});
  final String id;
  final String displayName;
  final String avatar;
}

/// One line of the members list.
class MemberLine {
  const MemberLine({required this.userId, required this.displayName, required this.avatar, required this.role, required this.isMe});
  final String userId;
  final String displayName;
  final String avatar;
  final TripRole role;
  final bool isMe;
}

TripRole roleOfKey(String key) => switch (key) {
  'owner' => TripRole.owner,
  'guide' => TripRole.guide,
  _ => TripRole.member,
};

/// The list to show: stored members (owner first, then guides, then members, by name), plus the
/// signed-in person themselves when the server has not delivered their own row yet.
List<MemberLine> buildMemberLines({
  required Trip trip,
  required List<TripMember> members,
  required String? myId,
  required String myName,
  required String myAvatar,
}) {
  final lines = <MemberLine>[
    for (final m in members)
      MemberLine(
        userId: m.userId,
        displayName: m.displayName.isEmpty ? '（未命名）' : m.displayName,
        avatar: m.avatar.isEmpty ? '🙂' : m.avatar,
        role: roleOfKey(m.role),
        isMe: m.userId == myId,
      ),
  ];
  if (myId != null && !lines.any((l) => l.isMe)) {
    final role = roleFor(trip: trip, accountId: myId, members: members);
    lines.add(MemberLine(userId: myId, displayName: myName, avatar: myAvatar.isEmpty ? '🙂' : myAvatar, role: role, isMe: true));
  }
  lines.sort((a, b) {
    final r = a.role.index.compareTo(b.role.index);
    return r != 0 ? r : a.displayName.compareTo(b.displayName);
  });
  return lines;
}

/// Who may change or remove [target]: the owner manages everyone else; a guide manages team members.
/// The owner's own row is never editable.
bool canManageMember({required TripRole me, required TripRole target}) {
  if (target == TripRole.owner) return false;
  return switch (me) {
    TripRole.owner => true,
    TripRole.guide => target == TripRole.member,
    TripRole.member => false,
  };
}

bool canInvite(TripRole me) => me.canEditShared;
