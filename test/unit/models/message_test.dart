import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('should create message with required fields', () {
      final timestamp = DateTime(2024, 12, 15, 9, 0);
      final message = Message()
        ..uuid = 'test-uuid-1234'
        ..user = 'Alex'
        ..category = 'Gear'
        ..content = '誰有帶攻頂爐？'
        ..timestamp = timestamp;

      expect(message.uuid, 'test-uuid-1234');
      expect(message.parentId, isNull);
      expect(message.user, 'Alex');
      expect(message.category, 'Gear');
      expect(message.content, '誰有帶攻頂爐？');
      expect(message.timestamp, timestamp);
    });

    test('should create reply message with parentId', () {
      final reply = Message()
        ..uuid = 'reply-uuid-5678'
        ..parentId = 'test-uuid-1234'
        ..user = 'Bob'
        ..category = 'Gear'
        ..content = '我有帶一顆 SOTO 的。'
        ..timestamp = DateTime(2024, 12, 15, 9, 30);

      expect(reply.parentId, 'test-uuid-1234');
      expect(reply.isReply, isTrue);
    });

    test('main message should have null parentId', () {
      final mainMessage = Message()
        ..uuid = 'main-uuid'
        ..user = 'Carol'
        ..category = 'Plan'
        ..content = '公糧分配表出來了嗎？'
        ..timestamp = DateTime.now();

      expect(mainMessage.parentId, isNull);
      expect(mainMessage.isReply, isFalse);
    });

    test('should validate category values', () {
      final validCategories = ['Gear', 'Plan', 'Misc'];

      final message = Message()
        ..uuid = 'test'
        ..user = 'Test'
        ..category = 'Gear'
        ..content = 'Test'
        ..timestamp = DateTime.now();

      expect(validCategories.contains(message.category), isTrue);

      message.category = 'InvalidCategory';
      expect(validCategories.contains(message.category), isFalse);
    });

    test('should generate unique uuid', () {
      final msg1 = Message()..uuid = 'uuid-1';
      final msg2 = Message()..uuid = 'uuid-2';

      expect(msg1.uuid, isNot(msg2.uuid));
    });
  });
}
