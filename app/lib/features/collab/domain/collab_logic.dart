import '../../../core/db/app_database.dart';
import '../../../core/sync/vote_id.dart';
import '../../trips/domain/trip_logic.dart';

export '../../../core/sync/vote_id.dart'
    show guestVoterId, voteIdFor, voteNamespace;

// Pure rules of the discussion tab (messages and polls). No database, no widgets, no clock:
// "now" is always passed in.

const messageMaxLength = 1000;
const pollTitleMaxLength = 200;
const pollOptionMinCount = 2;
const pollOptionMaxCount = 20;
const pollOptionMaxLength = 100;

/// Shown for an author who is no longer in the trip's member list.
const departedMemberName = '已離開的成員';

// ------------------------------------------------------------------ validation

/// Null when [body] is acceptable as a message (1..1000 characters after trimming).
String? validateMessageBody(String body) {
  final t = body.trim();
  if (t.isEmpty) return '請輸入留言內容';
  if (t.length > messageMaxLength) return '留言最多 $messageMaxLength 字';
  return null;
}

String? validatePollTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return '請輸入投票標題';
  if (t.length > pollTitleMaxLength) return '標題最多 $pollTitleMaxLength 字';
  return null;
}

String? validateOptionText(String text) {
  final t = text.trim();
  if (t.isEmpty) return '請輸入選項內容';
  if (t.length > pollOptionMaxLength) return '選項最多 $pollOptionMaxLength 字';
  return null;
}

/// Options as they will be stored: trimmed, blanks dropped.
List<String> cleanOptions(Iterable<String> raw) => [
  for (final o in raw)
    if (o.trim().isNotEmpty) o.trim(),
];

/// Null when a poll with [title] and [options] (already cleaned) may be created.
String? validatePollDraft(String title, List<String> options) {
  final t = validatePollTitle(title);
  if (t != null) return t;
  if (options.length < pollOptionMinCount) {
    return '至少要有 $pollOptionMinCount 個選項';
  }
  if (options.length > pollOptionMaxCount) return '最多 $pollOptionMaxCount 個選項';
  for (final o in options) {
    final e = validateOptionText(o);
    if (e != null) return e;
  }
  return null;
}

// ------------------------------------------------------------------ people

/// Who wrote something, as shown to the reader.
class Author {
  const Author({
    required this.name,
    required this.avatar,
    required this.isMe,
    this.departed = false,
  });
  final String name;
  final String avatar;
  final bool isMe;
  final bool departed;
}

/// True when a row written by [userId] is mine. A null author is something written here before
/// signing in, which is also mine.
bool isMineUser(String? userId, String? myId) =>
    userId == null || (myId != null && userId == myId);

/// Name and avatar of [userId] from the trip's member rows. Someone who is not (or no longer) a member
/// shows as [departedMemberName]; the signed-in person always resolves to themselves.
Author resolveAuthor(
  String? userId, {
  required List<TripMember> members,
  required String? myId,
  String myName = '',
  String myAvatar = '',
}) {
  final mine = isMineUser(userId, myId);
  if (userId != null) {
    for (final m in members) {
      if (m.userId == userId) {
        return Author(
          name: m.displayName.isEmpty ? '（未命名）' : m.displayName,
          avatar: m.avatar.isEmpty ? '🙂' : m.avatar,
          isMe: mine,
        );
      }
    }
  }
  if (mine) {
    return Author(
      name: myName.isEmpty ? '我' : myName,
      avatar: myAvatar.isEmpty ? '🙂' : myAvatar,
      isMe: true,
    );
  }
  return const Author(
    name: departedMemberName,
    avatar: '👤',
    isMe: false,
    departed: true,
  );
}

// ------------------------------------------------------------------ messages

/// A top-level message with its replies (oldest first).
class MessageThread {
  const MessageThread(this.message, this.replies);
  final TripMessage message;
  final List<TripMessage> replies;
}

int _byTime(TripMessage a, TripMessage b) {
  final c = a.createdAt.compareTo(b.createdAt);
  return c != 0 ? c : a.id.compareTo(b.id);
}

/// Top-level messages oldest first (newest last), each with its replies. A reply whose parent is
/// not stored (yet, or any more) is shown as a top-level message of its own.
List<MessageThread> buildThreads(List<TripMessage> messages) {
  final topIds = {
    for (final m in messages)
      if (m.parentId == null) m.id,
  };
  final replies = <String, List<TripMessage>>{};
  final tops = <TripMessage>[];
  for (final m in messages) {
    final parent = m.parentId;
    if (parent != null && topIds.contains(parent)) {
      replies.putIfAbsent(parent, () => []).add(m);
    } else {
      tops.add(m);
    }
  }
  tops.sort(_byTime);
  return [
    for (final m in tops) MessageThread(m, [...?replies[m.id]]..sort(_byTime)),
  ];
}

/// Only the author may change a message.
bool canEditMessage({required bool isMine}) => isMine;

/// The author, or the owner and guides, may delete a message.
bool canDeleteMessage({required TripRole role, required bool isMine}) =>
    isMine || role.canEditShared;

/// Only top-level messages take replies.
bool canReplyTo(TripMessage m) => m.parentId == null;

// ------------------------------------------------------------------ polls

enum PollState { open, closed, expired }

/// Closed by hand, or past its deadline on this device's clock.
PollState pollStateOf(Poll poll, DateTime now) {
  if (poll.status == 'closed') return PollState.closed;
  final d = poll.deadline;
  if (d != null && !now.isBefore(d)) return PollState.expired;
  return PollState.open;
}

bool canVote(PollState state) => state == PollState.open;

/// Creating, closing, reopening and deleting polls.
bool canManagePolls(TripRole role) => role.canEditShared;

/// The owner and guides may always add options; members only when the poll allows it and is open.
bool canAddOption({
  required TripRole role,
  required Poll poll,
  required PollState state,
}) {
  if (role.canEditShared) return true;
  return poll.allowAddOption && state == PollState.open;
}

/// The owner and guides may remove any option; members only the ones they added.
bool canDeleteOption({
  required TripRole role,
  required PollOption option,
  required String? myId,
}) {
  if (role.canEditShared) return true;
  return myId != null && option.createdBy == myId;
}

/// One option with its votes.
class OptionTally {
  const OptionTally({
    required this.option,
    required this.voterIds,
    required this.mine,
  });
  final PollOption option;

  /// Voters ([guestVoterId] for a vote cast before signing in), in vote order.
  final List<String> voterIds;
  final bool mine;
  int get count => voterIds.length;
}

class PollTally {
  const PollTally({
    required this.options,
    required this.showResults,
    required this.voterCount,
  });

  /// In display order.
  final List<OptionTally> options;

  /// False for a blind poll that is still open. [OptionTally.mine] is always filled in.
  final bool showResults;

  /// Distinct people who voted.
  final int voterCount;

  int get maxCount => options.fold(0, (m, o) => o.count > m ? o.count : m);
  Set<String> get myOptionIds => {
    for (final o in options)
      if (o.mine) o.option.id,
  };
}

/// Options in display order: `sort_order`, then id (ids are time-ordered).
List<PollOption> sortedOptions(Iterable<PollOption> options) =>
    [...options]..sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

/// Counts the votes of [poll]. In a single-choice poll only each voter's newest vote counts (by
/// `updatedAt`), however many rows they have. Votes for options that are not in [options] are ignored.
/// A blind poll hides the counts and voters until it is closed or expired, but [OptionTally.mine] always shows.
PollTally tallyPoll({
  required Poll poll,
  required List<PollOption> options,
  required List<PollVote> votes,
  required PollState state,
  required String? myId,
}) {
  final ordered = sortedOptions(options.where((o) => o.pollId == poll.id));
  final known = {for (final o in ordered) o.id};
  var mine = votes
      .where((v) => v.pollId == poll.id && known.contains(v.optionId))
      .toList();

  if (!poll.allowMultiple) {
    final newest = <String, PollVote>{};
    for (final v in mine) {
      final key = v.userId ?? guestVoterId;
      final cur = newest[key];
      if (cur == null ||
          v.updatedAt.isAfter(cur.updatedAt) ||
          (v.updatedAt == cur.updatedAt && v.id.compareTo(cur.id) > 0)) {
        newest[key] = v;
      }
    }
    mine = newest.values.toList();
  }
  mine.sort((a, b) {
    final c = a.updatedAt.compareTo(b.updatedAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  });

  final show = !poll.blind || state != PollState.open;
  return PollTally(
    options: [
      for (final o in ordered)
        OptionTally(
          option: o,
          voterIds: show
              ? [
                  for (final v in mine)
                    if (v.optionId == o.id) v.userId ?? guestVoterId,
                ]
              : const [],
          mine: mine.any(
            (v) => v.optionId == o.id && isMineUser(v.userId, myId),
          ),
        ),
    ],
    showResults: show,
    voterCount: show
        ? {for (final v in mine) v.userId ?? guestVoterId}.length
        : 0,
  );
}
