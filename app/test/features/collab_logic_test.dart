import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/collab/domain/collab_logic.dart';
import 'package:summitmate/features/trips/domain/trip_logic.dart';

TripMessage msg(String id, int minute, {String? parent, String? user = 'u1'}) =>
    TripMessage(
      id: id,
      tripId: 't',
      userId: user,
      parentId: parent,
      body: id,
      createdAt: DateTime.utc(2026, 5, 1, 10, minute),
    );

Poll poll({
  String status = 'open',
  DateTime? deadline,
  bool multiple = false,
  bool blind = false,
  bool addOption = false,
}) => Poll(
  id: 'p',
  tripId: 't',
  title: 'T',
  description: '',
  deadline: deadline,
  allowMultiple: multiple,
  allowAddOption: addOption,
  blind: blind,
  status: status,
  createdAt: DateTime.utc(2026, 5, 1),
);

PollOption opt(String id, {int order = 0, String? by}) => PollOption(
  id: id,
  pollId: 'p',
  tripId: 't',
  label: id,
  sortOrder: order,
  createdBy: by,
);

PollVote vote(String option, String? user, int minute) => PollVote(
  id: '$option:$user',
  pollId: 'p',
  optionId: option,
  tripId: 't',
  userId: user,
  updatedAt: DateTime.utc(2026, 5, 1, 10, minute),
);

TripMember member(String user, String name, {String avatar = '🦊'}) =>
    TripMember(
      id: 'm$user',
      tripId: 't',
      userId: user,
      role: 'member',
      displayName: name,
      avatar: avatar,
    );

void main() {
  group('validation', () {
    test('message length is 1..1000 after trimming', () {
      expect(validateMessageBody('  '), isNotNull);
      expect(validateMessageBody('a'), isNull);
      expect(validateMessageBody('a' * 1000), isNull);
      expect(validateMessageBody('a' * 1001), isNotNull);
    });

    test('poll title is 1..200', () {
      expect(validatePollTitle(''), isNotNull);
      expect(validatePollTitle('a' * 200), isNull);
      expect(validatePollTitle('a' * 201), isNotNull);
    });

    test('a poll needs 2..20 options of 1..100 characters', () {
      expect(validatePollDraft('t', ['a']), isNotNull);
      expect(validatePollDraft('t', ['a', 'b']), isNull);
      expect(validatePollDraft('t', List.generate(20, (i) => 'o$i')), isNull);
      expect(
        validatePollDraft('t', List.generate(21, (i) => 'o$i')),
        isNotNull,
      );
      expect(validatePollDraft('t', ['a', 'b' * 101]), isNotNull);
      expect(validatePollDraft('t', ['a', 'b' * 100]), isNull);
      expect(validatePollDraft('', ['a', 'b']), isNotNull);
    });

    test('blank options are dropped and the rest trimmed', () {
      expect(cleanOptions([' a ', '', '  ', 'b']), ['a', 'b']);
    });
  });

  group('vote ids', () {
    test('match the server rule (uuid v5 of "<option>:<user>", checked against python uuid5)', () {
      expect(
        voteIdFor(
          '11111111-1111-4111-8111-111111111111',
          '22222222-2222-4222-8222-222222222222',
        ),
        'f2d12f34-8d77-57bc-aa9e-1d07aa680904',
      );
      expect(
        voteIdFor('opt-1', guestVoterId),
        '7b050c14-8e31-56e6-a50c-039ba277afaf',
      );
    });
  });

  group('threads', () {
    test(
      'top-level messages are oldest first and replies hang under their parent',
      () {
        final threads = buildThreads([
          msg('b', 5),
          msg('r2', 9, parent: 'a'),
          msg('a', 1),
          msg('r1', 3, parent: 'a'),
          msg('c', 8),
        ]);
        expect(threads.map((t) => t.message.id), ['a', 'b', 'c']);
        expect(threads.first.replies.map((r) => r.id), ['r1', 'r2']);
        expect(threads[1].replies, isEmpty);
      },
    );

    test('a reply whose parent is missing shows as a top-level message', () {
      final threads = buildThreads([
        msg('a', 1),
        msg('orphan', 2, parent: 'gone'),
      ]);
      expect(threads.map((t) => t.message.id), ['a', 'orphan']);
    });

    test('equal times fall back to the id so the order is stable', () {
      expect(
        buildThreads([msg('b', 1), msg('a', 1)]).map((t) => t.message.id),
        ['a', 'b'],
      );
    });

    test('only top-level messages take replies', () {
      expect(canReplyTo(msg('a', 1)), isTrue);
      expect(canReplyTo(msg('r', 2, parent: 'a')), isFalse);
    });
  });

  group('who may change a message', () {
    test('delete: the author, the owner and guides', () {
      expect(canDeleteMessage(role: TripRole.member, isMine: true), isTrue);
      expect(canDeleteMessage(role: TripRole.member, isMine: false), isFalse);
      expect(canDeleteMessage(role: TripRole.guide, isMine: false), isTrue);
      expect(canDeleteMessage(role: TripRole.owner, isMine: false), isTrue);
    });

    test('edit: only the author', () {
      expect(canEditMessage(isMine: true), isTrue);
      expect(canEditMessage(isMine: false), isFalse);
    });
  });

  group('authors', () {
    final members = [member('u1', 'Anna', avatar: '🐻'), member('u2', 'Bob')];

    test('name and avatar come from the member row', () {
      final a = resolveAuthor('u1', members: members, myId: 'u2');
      expect(
        [a.name, a.avatar, a.isMe, a.departed],
        ['Anna', '🐻', false, false],
      );
      expect(resolveAuthor('u2', members: members, myId: 'u2').isMe, isTrue);
    });

    test('someone who is no longer a member shows as departed', () {
      final a = resolveAuthor('gone', members: members, myId: 'u2');
      expect([a.name, a.departed, a.isMe], [departedMemberName, true, false]);
    });

    test('my own rows resolve to me even without a member row, and so do rows written as a guest', () {
      expect(
        resolveAuthor('me', members: const [], myId: 'me', myName: 'Mia').name,
        'Mia',
      );
      final guest = resolveAuthor(null, members: const [], myId: null);
      expect([guest.name, guest.isMe], ['我', true]);
      expect(isMineUser(null, 'x'), isTrue);
      expect(isMineUser('y', 'x'), isFalse);
      expect(isMineUser('y', null), isFalse);
    });
  });

  group('poll state', () {
    final deadline = DateTime.utc(2026, 5, 10, 12);

    test('closed by hand, expired by deadline, otherwise open', () {
      expect(pollStateOf(poll(), DateTime.utc(2030)), PollState.open);
      expect(
        pollStateOf(
          poll(deadline: deadline),
          DateTime.utc(2026, 5, 10, 11, 59),
        ),
        PollState.open,
      );
      expect(
        pollStateOf(poll(deadline: deadline), deadline),
        PollState.expired,
      );
      expect(
        pollStateOf(
          poll(status: 'closed', deadline: deadline),
          DateTime.utc(2026, 5, 1),
        ),
        PollState.closed,
      );
      expect(
        pollStateOf(
          poll(status: 'closed', deadline: deadline),
          DateTime.utc(2027),
        ),
        PollState.closed,
      );
    });

    test('voting only while open', () {
      expect(canVote(PollState.open), isTrue);
      expect(canVote(PollState.closed), isFalse);
      expect(canVote(PollState.expired), isFalse);
    });

    test('managing polls is for the owner and guides', () {
      expect(canManagePolls(TripRole.owner), isTrue);
      expect(canManagePolls(TripRole.guide), isTrue);
      expect(canManagePolls(TripRole.member), isFalse);
    });

    test('members add options only when allowed and open; editors always', () {
      final closed = poll(status: 'closed', addOption: true);
      expect(
        canAddOption(
          role: TripRole.member,
          poll: poll(),
          state: PollState.open,
        ),
        isFalse,
      );
      expect(
        canAddOption(
          role: TripRole.member,
          poll: poll(addOption: true),
          state: PollState.open,
        ),
        isTrue,
      );
      expect(
        canAddOption(
          role: TripRole.member,
          poll: closed,
          state: PollState.closed,
        ),
        isFalse,
      );
      expect(
        canAddOption(role: TripRole.guide, poll: poll(), state: PollState.open),
        isTrue,
      );
    });

    test('members remove only their own options', () {
      expect(
        canDeleteOption(
          role: TripRole.member,
          option: opt('a', by: 'me'),
          myId: 'me',
        ),
        isTrue,
      );
      expect(
        canDeleteOption(
          role: TripRole.member,
          option: opt('a', by: 'other'),
          myId: 'me',
        ),
        isFalse,
      );
      expect(
        canDeleteOption(role: TripRole.member, option: opt('a'), myId: null),
        isFalse,
      );
      expect(
        canDeleteOption(
          role: TripRole.owner,
          option: opt('a', by: 'other'),
          myId: 'me',
        ),
        isTrue,
      );
    });
  });

  group('results', () {
    final options = [
      opt('b', order: 1),
      opt('a', order: 0),
      opt('c', order: 2),
    ];

    PollTally tally(
      Poll p,
      List<PollVote> votes, {
      PollState state = PollState.open,
      String? me = 'me',
    }) => tallyPoll(
      poll: p,
      options: options,
      votes: votes,
      state: state,
      myId: me,
    );

    test('counts per option in display order, with the voters', () {
      final t = tally(poll(multiple: true), [
        vote('a', 'u1', 1),
        vote('b', 'u1', 2),
        vote('a', 'me', 3),
      ]);
      expect(t.options.map((o) => o.option.id), ['a', 'b', 'c']);
      expect(t.options.map((o) => o.count), [2, 1, 0]);
      expect(t.options.first.voterIds, ['u1', 'me']);
      expect(t.voterCount, 2);
      expect(t.myOptionIds, {'a'});
      expect(t.maxCount, 2);
    });

    test('single choice counts only each voter\'s newest vote', () {
      final t = tally(poll(), [
        vote('a', 'u1', 1),
        vote('b', 'u1', 5),
        vote('c', 'u2', 2),
      ]);
      expect(t.options.map((o) => o.count), [0, 1, 1]);
      expect(t.voterCount, 2);
    });

    test(
      'votes for unknown options are ignored and guest votes count as mine',
      () {
        final t = tally(poll(), [
          vote('zzz', 'u1', 1),
          vote('a', null, 2),
        ], me: null);
        expect(t.options.map((o) => o.count), [1, 0, 0]);
        expect(t.options.first.mine, isTrue);
        expect(t.options.first.voterIds, [guestVoterId]);
      },
    );

    test('a blind poll hides counts and voters while open, but always shows my own votes', () {
      final votes = [vote('a', 'u1', 1), vote('b', 'me', 2)];
      final t = tally(poll(blind: true), votes);
      expect(t.showResults, isFalse);
      expect(t.options.map((o) => o.count), [0, 0, 0]);
      expect(t.options.every((o) => o.voterIds.isEmpty), isTrue);
      expect(t.voterCount, 0);
      expect(t.myOptionIds, {'b'});
    });

    test('a blind poll shows its results once closed or expired', () {
      final votes = [vote('a', 'u1', 1), vote('b', 'me', 2)];
      for (final s in [PollState.closed, PollState.expired]) {
        final t = tally(poll(blind: true), votes, state: s);
        expect(t.showResults, isTrue);
        expect(t.options.map((o) => o.count), [1, 1, 0]);
      }
      expect(tally(poll(), votes).showResults, isTrue);
    });
  });
}
