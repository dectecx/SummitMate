import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/services/log_service.dart';

void main() {
  group('LogEntry', () {
    test('should create from constructor', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 12, 16, 10, 30, 0),
        level: LogLevel.info,
        message: 'Test message',
        source: 'TestSource',
      );

      expect(entry.level, LogLevel.info);
      expect(entry.message, 'Test message');
      expect(entry.source, 'TestSource');
    });

    test('should format correctly', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 12, 16, 10, 30, 45),
        level: LogLevel.warning,
        message: 'Warning message',
        source: 'Test',
      );

      expect(entry.formatted, '10:30:45 [WARNING] [Test] Warning message');
    });

    test('should format without source', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 12, 16, 10, 30, 45),
        level: LogLevel.error,
        message: 'Error occurred',
      );

      expect(entry.formatted, '10:30:45 [ERROR  ] Error occurred');
    });

    test('should convert to/from JSON', () {
      final original = LogEntry(
        timestamp: DateTime(2024, 12, 16, 10, 30, 0),
        level: LogLevel.debug,
        message: 'Debug info',
        source: 'Module',
      );

      final json = original.toJson();
      expect(json['level'], 'debug');
      expect(json['message'], 'Debug info');
      expect(json['source'], 'Module');

      final restored = LogEntry.fromJson(json);
      expect(restored.level, original.level);
      expect(restored.message, original.message);
      expect(restored.source, original.source);
    });
  });

  group('LogLevel', () {
    test('should have 4 levels', () {
      expect(LogLevel.values.length, 4);
    });

    test('should have correct values', () {
      expect(LogLevel.debug.name, 'debug');
      expect(LogLevel.info.name, 'info');
      expect(LogLevel.warning.name, 'warning');
      expect(LogLevel.error.name, 'error');
    });
  });
}
