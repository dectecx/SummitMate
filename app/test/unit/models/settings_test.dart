import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/settings.dart';

void main() {
  group('Settings Model Tests', () {
    test('should create with default values', () {
      final settings = Settings();

      expect(settings.username, isEmpty);
      expect(settings.lastSyncTime, isNull);
    });

    test('should create with withDefaults factory', () {
      final settings = Settings.withDefaults();

      expect(settings.username, isEmpty);
      expect(settings.lastSyncTime, isNull);
    });

    test('should update username', () {
      final settings = Settings();
      settings.username = 'TestUser';

      expect(settings.username, equals('TestUser'));
    });

    test('should update lastSyncTime', () {
      final settings = Settings();
      final now = DateTime.now();
      settings.lastSyncTime = now;

      expect(settings.lastSyncTime, equals(now));
    });
  });
}
