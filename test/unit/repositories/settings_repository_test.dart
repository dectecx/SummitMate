import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/data/repositories/settings_repository.dart';

void main() {
  late Isar isar;
  late SettingsRepository repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [SettingsSchema],
      directory: '',
      name: 'test_settings_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = SettingsRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('SettingsRepository Tests', () {
    test('should return default settings when none exist', () async {
      final settings = await repository.getSettings();

      expect(settings.id, 1);
      expect(settings.username, isEmpty);
      expect(settings.lastSyncTime, isNull);
    });

    test('should update username', () async {
      await repository.updateUsername('Alex');

      final settings = await repository.getSettings();
      expect(settings.username, 'Alex');
    });

    test('should update last sync time', () async {
      final syncTime = DateTime(2024, 12, 15, 10, 30);
      await repository.updateLastSyncTime(syncTime);

      final settings = await repository.getSettings();
      expect(settings.lastSyncTime, syncTime);
    });

    test('should persist settings across multiple calls', () async {
      await repository.updateUsername('Bob');
      await repository.updateLastSyncTime(DateTime.now());

      final settings = await repository.getSettings();
      expect(settings.username, 'Bob');
      expect(settings.lastSyncTime, isNotNull);
    });

    test('should reset settings', () async {
      await repository.updateUsername('Carol');
      await repository.resetSettings();

      final settings = await repository.getSettings();
      expect(settings.username, isEmpty);
    });
  });
}
