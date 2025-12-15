import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('should create with default values', () {
      final message = Message();

      expect(message.uuid, isEmpty);
      expect(message.parentId, isNull);
      expect(message.user, isEmpty);
      expect(message.category, isEmpty);
      expect(message.content, isEmpty);
      expect(message.timestamp, isNotNull);
    });

    test('should create with named parameters', () {
      final timestamp = DateTime(2024, 12, 15, 10, 30);
      final message = Message(
        uuid: 'test-uuid-123',
        parentId: null,
        user: 'Alex',
        category: 'Gear',
        content: '誰有帶攻頂爐？',
        timestamp: timestamp,
      );

      expect(message.uuid, equals('test-uuid-123'));
      expect(message.parentId, isNull);
      expect(message.user, equals('Alex'));
      expect(message.category, equals('Gear'));
      expect(message.content, equals('誰有帶攻頂爐？'));
      expect(message.timestamp, equals(timestamp));
    });

    test('should report isReply false when parentId is null', () {
      final message = Message();

      expect(message.isReply, isFalse);
    });

    test('should report isReply true when parentId is set', () {
      final message = Message(parentId: 'parent-uuid');

      expect(message.isReply, isTrue);
    });

    test('should convert to/from JSON', () {
      final message = Message(
        uuid: 'test-uuid',
        user: 'Bob',
        category: 'Plan',
        content: '明天幾點出發?',
        timestamp: DateTime(2024, 12, 15, 10, 0),
      );

      final json = message.toJson();
      final restored = Message.fromJson(json);

      expect(restored.uuid, equals(message.uuid));
      expect(restored.user, equals(message.user));
      expect(restored.category, equals(message.category));
      expect(restored.content, equals(message.content));
    });

    test('should handle nested reply structure', () {
      final parent = Message(uuid: 'parent-uuid', content: '主留言');
      final reply = Message(uuid: 'reply-uuid', parentId: parent.uuid, content: '回覆');

      expect(reply.isReply, isTrue);
      expect(reply.parentId, equals(parent.uuid));
    });
  });
}
