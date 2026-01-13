import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('should create with default values', () {
      final message = Message(
        id: 'default-id',
        createdAt: DateTime.now(),
        createdBy: '',
        updatedAt: DateTime.now(),
        updatedBy: '',
      );

      expect(message.id, 'default-id');
      expect(message.parentId, isNull);
      expect(message.user, isEmpty);
      expect(message.category, isEmpty);
      expect(message.content, isEmpty);
      expect(message.timestamp, isNotNull);
    });

    test('should create with named parameters', () {
      final timestamp = DateTime(2024, 12, 15, 10, 30);
      final message = Message(
        id: 'test-uuid-123',
        parentId: null,
        user: 'Alex',
        category: 'Gear',
        content: '誰有帶攻頂爐？',
        timestamp: timestamp,
        createdAt: timestamp,
        createdBy: 'Alex',
        updatedAt: timestamp,
        updatedBy: 'Alex',
      );

      expect(message.id, equals('test-uuid-123'));
      expect(message.parentId, isNull);
      expect(message.user, equals('Alex'));
      expect(message.category, equals('Gear'));
      expect(message.content, equals('誰有帶攻頂爐？'));
      expect(message.timestamp, equals(timestamp));
    });

    test('should report isReply false when parentId is null', () {
      final message = Message(
          id: 'no-reply-id',
          createdAt: DateTime.now(),
          createdBy: '',
          updatedAt: DateTime.now(),
          updatedBy: '');

      expect(message.isReply, isFalse);
    });

    test('should report isReply true when parentId is set', () {
      final message = Message(
          id: 'test-id-3',
          parentId: 'parent-uuid',
          createdAt: DateTime.now(),
          createdBy: '',
          updatedAt: DateTime.now(),
          updatedBy: '');

      expect(message.isReply, isTrue);
    });

    test('should convert to/from JSON', () {
      final message = Message(
        id: 'test-uuid',
        user: 'Bob',
        category: 'Chat',
        content: '明天幾點出發?',
        timestamp: DateTime(2024, 12, 15, 10, 0),
        createdAt: DateTime(2024, 12, 15, 10, 0),
        createdBy: 'Bob',
        updatedAt: DateTime(2024, 12, 15, 10, 0),
        updatedBy: 'Bob',
      );

      final json = message.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, equals(message.id));
      expect(restored.user, equals(message.user));
      expect(restored.category, equals(message.category));
      expect(restored.content, equals(message.content));
    });

    test('should handle nested reply structure', () {
      final parent = Message(
          id: 'parent-uuid',
          content: '主留言',
          createdAt: DateTime.now(),
          createdBy: '',
          updatedAt: DateTime.now(),
          updatedBy: '');
      final reply = Message(
          id: 'reply-uuid',
          parentId: parent.id,
          content: '回覆',
          createdAt: DateTime.now(),
          createdBy: '',
          updatedAt: DateTime.now(),
          updatedBy: '');

      expect(reply.isReply, isTrue);
      expect(reply.parentId, equals(parent.id));
    });
  });
}
