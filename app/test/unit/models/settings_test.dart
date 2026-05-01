import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/domain.dart';

void main() {
  group('Settings Model Tests', () {
    test('should create with default values', () {
      const settings = Settings();

      expect(settings.username, isEmpty);
      expect(settings.lastSyncTime, isNull);
    });

    test('should update username via copyWith', () {
      const settings = Settings();
      final updated = settings.copyWith(username: 'TestUser');

      expect(updated.username, equals('TestUser'));
      expect(settings.username, isEmpty);
    });

    test('should update lastSyncTime via copyWith', () {
      const settings = Settings();
      final now = DateTime.now();
      final updated = settings.copyWith(lastSyncTime: now);

      expect(updated.lastSyncTime, equals(now));
      expect(settings.lastSyncTime, isNull);
    });
  });
}
