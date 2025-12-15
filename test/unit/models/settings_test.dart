import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/settings.dart';

void main() {
  group('Settings Model Tests', () {
    test('should create settings with default values', () {
      final settings = Settings();

      expect(settings.id, isNull);
      expect(settings.username, isEmpty);
      expect(settings.lastSyncTime, isNull);
    });

    test('should create settings with provided values', () {
      final syncTime = DateTime(2024, 12, 15, 10, 30);
      final settings = Settings()
        ..username = 'Alex'
        ..lastSyncTime = syncTime;

      expect(settings.username, 'Alex');
      expect(settings.lastSyncTime, syncTime);
    });

    test('should allow updating username', () {
      final settings = Settings()..username = 'Alex';

      settings.username = 'Bob';

      expect(settings.username, 'Bob');
    });

    test('should handle null lastSyncTime correctly', () {
      final settings = Settings()
        ..username = 'Alex'
        ..lastSyncTime = DateTime.now();

      settings.lastSyncTime = null;

      expect(settings.lastSyncTime, isNull);
    });
  });
}
