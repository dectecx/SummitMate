import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:summitmate/core/constants.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_message_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';

// ============================================================
// === MOCKS ===
// ============================================================

/// Mock Message Repository
class MockMessageRepository implements IMessageRepository {
  List<Message> messages = [];
  DateTime? lastSyncTime;

  @override
  Future<void> init() async {}

  @override
  List<Message> getAllMessages() => messages;

  @override
  List<Message> getMessagesByCategory(String category) => messages.where((msg) => msg.category == category).toList();

  @override
  List<Message> getMainMessages({String? category}) {
    var result = messages.where((msg) => !msg.isReply).toList();
    if (category != null) {
      result = result.where((msg) => msg.category == category).toList();
    }
    return result;
  }

  @override
  List<Message> getReplies(String parentUuid) => messages.where((msg) => msg.parentId == parentUuid).toList();

  @override
  Message? getByUuid(String uuid) {
    try {
      return messages.firstWhere((msg) => msg.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addMessage(Message message) async {
    messages.add(message);
  }

  @override
  Future<void> deleteByUuid(String uuid) async {
    messages.removeWhere((msg) => msg.uuid == uuid);
  }

  @override
  Future<void> syncFromCloud(List<Message> cloudMessages) async {
    messages = cloudMessages;
  }

  @override
  List<Message> getPendingMessages(Set<String> cloudUuids) =>
      messages.where((msg) => !cloudUuids.contains(msg.uuid)).toList();

  @override
  Stream<BoxEvent> watchAllMessages() => const Stream.empty();

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    lastSyncTime = time;
  }

  @override
  DateTime? getLastSyncTime() => lastSyncTime;

  @override
  Future<void> clearAll() async {
    messages.clear();
  }
}

/// Mock Trip Repository
class MockTripRepository implements ITripRepository {
  Trip? activeTrip;

  @override
  Future<void> init() async {}

  @override
  List<Trip> getAllTrips() => activeTrip != null ? [activeTrip!] : [];

  @override
  Trip? getActiveTrip() => activeTrip;

  @override
  Trip? getTripById(String id) => activeTrip?.id == id ? activeTrip : null;

  @override
  Future<void> addTrip(Trip trip) async {}

  @override
  Future<void> updateTrip(Trip trip) async {}

  @override
  Future<void> deleteTrip(String id) async {}

  @override
  Future<void> setActiveTrip(String tripId) async {}

  @override
  DateTime? getLastSyncTime() => null;

  @override
  Future<void> saveLastSyncTime(DateTime time) async {}
}

// ============================================================
// === TEST DATA ===
// ============================================================

Message createTestMessage({
  String uuid = 'msg-1',
  String? tripId = 'trip-1',
  String? parentId,
  String user = 'Alice',
  String category = 'Chat',
  String content = 'Test message',
  String avatar = '🐻',
}) {
  return Message(
    uuid: uuid,
    tripId: tripId,
    parentId: parentId,
    user: user,
    category: category,
    content: content,
    avatar: avatar,
    timestamp: DateTime.now(),
  );
}

Trip createTestTrip({String id = 'trip-1', String name = 'Test Trip'}) {
  return Trip(id: id, name: name, startDate: DateTime.now(), isActive: true, createdAt: DateTime.now());
}

// ============================================================
// === TESTS ===
// ============================================================
// Note: Tests focus on MessageRepository logic and message filtering.
// Tests for addMessage/deleteMessage/sync are skipped because they
// require SyncService which has complex dependencies.

void main() {
  group('MockMessageRepository', () {
    late MockMessageRepository repo;

    setUp(() {
      repo = MockMessageRepository();
    });

    test('getAllMessages returns all stored messages', () {
      repo.messages = [createTestMessage(uuid: 'msg-1'), createTestMessage(uuid: 'msg-2')];

      expect(repo.getAllMessages(), hasLength(2));
    });

    test('getMessagesByCategory filters correctly', () {
      repo.messages = [
        createTestMessage(uuid: 'msg-1', category: MessageCategory.chat),
        createTestMessage(uuid: 'msg-2', category: MessageCategory.gear),
      ];

      final chatMessages = repo.getMessagesByCategory(MessageCategory.chat);

      expect(chatMessages, hasLength(1));
      expect(chatMessages.first.category, MessageCategory.chat);
    });

    test('getMainMessages excludes replies', () {
      repo.messages = [
        createTestMessage(uuid: 'msg-1'),
        createTestMessage(uuid: 'msg-2', parentId: 'msg-1'), // Reply
      ];

      final mainMessages = repo.getMainMessages();

      expect(mainMessages, hasLength(1));
      expect(mainMessages.first.uuid, 'msg-1');
    });

    test('getReplies returns child messages', () {
      repo.messages = [
        createTestMessage(uuid: 'parent'),
        createTestMessage(uuid: 'reply-1', parentId: 'parent'),
        createTestMessage(uuid: 'reply-2', parentId: 'parent'),
      ];

      final replies = repo.getReplies('parent');

      expect(replies, hasLength(2));
    });

    test('getByUuid finds message', () {
      repo.messages = [createTestMessage(uuid: 'find-me')];

      final found = repo.getByUuid('find-me');

      expect(found, isNotNull);
      expect(found?.uuid, 'find-me');
    });

    test('getByUuid returns null when not found', () {
      repo.messages = [];

      final found = repo.getByUuid('not-exist');

      expect(found, isNull);
    });

    test('addMessage adds to list', () async {
      await repo.addMessage(createTestMessage(uuid: 'new'));

      expect(repo.messages, hasLength(1));
      expect(repo.messages.first.uuid, 'new');
    });

    test('deleteByUuid removes message', () async {
      repo.messages = [createTestMessage(uuid: 'delete-me')];

      await repo.deleteByUuid('delete-me');

      expect(repo.messages, isEmpty);
    });

    test('syncFromCloud replaces all messages', () async {
      repo.messages = [createTestMessage(uuid: 'old')];

      await repo.syncFromCloud([createTestMessage(uuid: 'new-1'), createTestMessage(uuid: 'new-2')]);

      expect(repo.messages, hasLength(2));
      expect(repo.messages.any((m) => m.uuid == 'old'), isFalse);
    });

    test('getPendingMessages returns messages not in cloud', () {
      repo.messages = [createTestMessage(uuid: 'local-1'), createTestMessage(uuid: 'synced-1')];

      final pending = repo.getPendingMessages({'synced-1'});

      expect(pending, hasLength(1));
      expect(pending.first.uuid, 'local-1');
    });

    test('clearAll removes all messages', () async {
      repo.messages = [createTestMessage(uuid: 'msg-1'), createTestMessage(uuid: 'msg-2')];

      await repo.clearAll();

      expect(repo.messages, isEmpty);
    });
  });

  group('Message model', () {
    test('isReply returns true when parentId is set', () {
      final reply = Message(uuid: 'reply', parentId: 'parent');
      final main = Message(uuid: 'main');

      expect(reply.isReply, isTrue);
      expect(main.isReply, isFalse);
    });
  });

  group('MockTripRepository', () {
    late MockTripRepository repo;

    setUp(() {
      repo = MockTripRepository();
    });

    test('getActiveTrip returns active trip', () {
      repo.activeTrip = createTestTrip(id: 'trip-1');

      expect(repo.getActiveTrip()?.id, 'trip-1');
    });

    test('getActiveTrip returns null when no active trip', () {
      expect(repo.getActiveTrip(), isNull);
    });

    test('getTripById returns matching trip', () {
      repo.activeTrip = createTestTrip(id: 'trip-1');

      expect(repo.getTripById('trip-1')?.id, 'trip-1');
      expect(repo.getTripById('trip-2'), isNull);
    });
  });

  group('Message filtering by trip', () {
    test('messages can be filtered by tripId', () {
      final messages = [
        createTestMessage(uuid: 'msg-1', tripId: 'trip-1'),
        createTestMessage(uuid: 'msg-2', tripId: 'trip-2'),
        createTestMessage(uuid: 'msg-3', tripId: null), // Global
      ];

      final trip1Messages = messages.where((m) => m.tripId == null || m.tripId == 'trip-1').toList();

      expect(trip1Messages, hasLength(2));
      expect(trip1Messages.any((m) => m.uuid == 'msg-1'), isTrue);
      expect(trip1Messages.any((m) => m.uuid == 'msg-3'), isTrue);
    });
  });
}
