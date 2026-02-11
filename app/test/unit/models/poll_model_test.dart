import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/poll.dart';

void main() {
  group('Poll & PollOption Model Tests', () {
    final testPollJson = {
      'id': 'poll-1',
      'title': 'Test Poll',
      'description': 'Description',
      'creator_id': 'user-1',
      'created_at': '2024-01-01T00:00:00Z',
      'created_by': 'user-1',
      'updated_at': '2024-01-01T00:00:00Z',
      'updated_by': 'user-1',
      'options': [
        {
          'id': 'opt-1',
          'poll_id': 'poll-1',
          'text': 'Option 1',
          'creator_id': 'user-1',
          'created_at': '2024-01-01T00:00:00Z',
          'created_by': 'user-1',
          'updated_at': '2024-01-01T00:00:00Z',
          'updated_by': 'user-1',
          'vote_count': 5,
          'voters': [
            {'user_id': 'u1', 'user_name': 'User 1'},
          ],
        },
      ],
      'my_votes': ['opt-1'],
      'total_votes': 5,
    };

    test('Positive: Should parse Poll and PollOption from JSON', () {
      final poll = Poll.fromJson(testPollJson);

      expect(poll.id, 'poll-1');
      expect(poll.title, 'Test Poll');
      expect(poll.options.length, 1);

      final option = poll.options.first;
      expect(option.id, 'opt-1');
      expect(option.text, 'Option 1');
      expect(option.voteCount, 5);
      expect(option.voters.first['user_name'], 'User 1');
      expect(poll.myVotes, contains('opt-1'));
    });

    test('Positive: Should convert Poll to JSON', () {
      final poll = Poll(
        id: 'poll-1',
        title: 'Title',
        creatorId: 'c1',
        totalVotes: 1,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        createdBy: 'c1',
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedBy: 'c1',
        options: [
          PollOption(
            id: 'o1',
            pollId: 'poll-1',
            text: 'Opt',
            creatorId: 'c1',
            voteCount: 1,
            createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
            createdBy: 'c1',
            updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
            updatedBy: 'c1',
          ),
        ],
      );

      final json = poll.toJson();

      expect(json['id'], 'poll-1');
      expect(json['options'][0]['id'], 'o1');
      expect(json['total_votes'], 1);
    });

    test('Edge: Should handle empty options and my_votes', () {
      final minimalJson = {
        'id': 'poll-2',
        'title': 'Empty Poll',
        'creator_id': 'u2',
        'created_at': '2024-01-01T00:00:00Z',
        'created_by': 'u2',
        'updated_at': '2024-01-01T00:00:00Z',
        'updated_by': 'u2',
      };

      final poll = Poll.fromJson(minimalJson);

      expect(poll.options, isEmpty);
      expect(poll.myVotes, isEmpty);
      expect(poll.totalVotes, 0);
    });

    test('Extreme: Should handle very large vote counts (as int)', () {
      final poll = Poll.fromJson({
        'id': 'p',
        'title': 'T',
        'creator_id': 'c',
        'created_at': '2024-01-01T00:00:00Z',
        'created_by': 'c',
        'updated_at': '2024-01-01T00:00:00Z',
        'updated_by': 'c',
        'total_votes': 999999999,
      });

      expect(poll.totalVotes, 999999999);
    });

    test('Exception: Should handle malformed dates gracefully (if possible)', () {
      // JsonSerializable by default throws if it can't parse DateTime unless handled
      final badDateJson = {'id': 'p', 'title': 'T', 'creator_id': 'c', 'created_at': 'not-a-date'};

      expect(() => Poll.fromJson(badDateJson), throwsA(isA<FormatException>()));
    });

    test('Logic: isActive and isExpired', () {
      final now = DateTime.now();

      final activePoll = Poll(
        id: '1',
        title: 'T',
        creatorId: 'c',
        createdAt: now,
        createdBy: 'c',
        updatedAt: now,
        updatedBy: 'c',
        deadline: now.add(const Duration(days: 1)),
        status: 'active',
      );

      final expiredPoll = Poll(
        id: '2',
        title: 'T',
        creatorId: 'c',
        createdAt: now.subtract(const Duration(days: 2)),
        createdBy: 'c',
        updatedAt: now,
        updatedBy: 'c',
        deadline: now.subtract(const Duration(days: 1)),
        status: 'active',
      );

      final closedPoll = Poll(
        id: '3',
        title: 'T',
        creatorId: 'c',
        createdAt: now,
        createdBy: 'c',
        updatedAt: now,
        updatedBy: 'c',
        status: 'ended',
      );

      expect(activePoll.isActive, isTrue);
      expect(activePoll.isExpired, isFalse);

      expect(expiredPoll.isActive, isFalse);
      expect(expiredPoll.isExpired, isTrue);

      expect(closedPoll.isActive, isFalse);
    });
  });
}
