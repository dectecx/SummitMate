import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/data/repositories/settings_repository.dart';
import 'package:summitmate/data/datasources/interfaces/i_settings_local_data_source.dart';

// Mocks
class MockSettingsLocalDataSource extends Mock implements ISettingsLocalDataSource {}

class MockSettings extends Mock implements Settings {}

void main() {
  late SettingsRepository repository;
  late MockSettingsLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(Settings());
  });

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();

    // Inject mock via constructor
    repository = SettingsRepository(localDataSource: mockDataSource);

    // Default init behavior
    when(() => mockDataSource.init()).thenAnswer((_) async {});
  });

  group('SettingsRepository', () {
    test('init() should return Success', () async {
      // Act
      final result = await repository.init();

      // Assert
      expect(result, isA<Success>());
      verify(() => mockDataSource.init()).called(1);
    });

    test('getSettings() returns existing settings if present', () async {
      // Arrange
      await repository.init();
      final settings = Settings(username: 'Test User');
      when(() => mockDataSource.getSettings()).thenReturn(settings);

      // Act
      final result = repository.getSettings();

      // Assert
      expect(result, equals(settings));
      expect(result.username, 'Test User');
    });

    test('getSettings() creates default settings if missing', () async {
      // Arrange
      await repository.init();
      when(() => mockDataSource.getSettings()).thenReturn(null);
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

      // Act
      final result = repository.getSettings();

      // Assert
      expect(result.username, ''); // Default
      expect(result.avatar, '🐻'); // Default
      verify(() => mockDataSource.saveSettings(any())).called(1);
    });

    test('updateUsername() updates settings and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockDataSource.getSettings()).thenReturn(mockSettings);
      when(() => mockDataSource.saveSettings(mockSettings)).thenAnswer((_) async {});

      // Act
      await repository.updateUsername('New Name');

      // Assert
      verify(() => mockSettings.username = 'New Name').called(1);
      verify(() => mockDataSource.saveSettings(mockSettings)).called(1);
    });

    test('updateOfflineMode() updates value and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockDataSource.getSettings()).thenReturn(mockSettings);
      when(() => mockDataSource.saveSettings(mockSettings)).thenAnswer((_) async {});

      // Act
      await repository.updateOfflineMode(true);

      // Assert
      verify(() => mockSettings.isOfflineMode = true).called(1);
      verify(() => mockDataSource.saveSettings(mockSettings)).called(1);
    });

    test('updateAvatar() updates avatar and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockDataSource.getSettings()).thenReturn(mockSettings);
      when(() => mockDataSource.saveSettings(mockSettings)).thenAnswer((_) async {});

      // Act
      await repository.updateAvatar('🦊');

      // Assert
      verify(() => mockSettings.avatar = '🦊').called(1);
      verify(() => mockDataSource.saveSettings(mockSettings)).called(1);
    });

    test('updateLastSyncTime() updates time and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockDataSource.getSettings()).thenReturn(mockSettings);
      when(() => mockDataSource.saveSettings(mockSettings)).thenAnswer((_) async {});
      final time = DateTime(2023, 1, 1);

      // Act
      await repository.updateLastSyncTime(time);

      // Assert
      verify(() => mockSettings.lastSyncTime = time).called(1);
      verify(() => mockDataSource.saveSettings(mockSettings)).called(1);
    });

    test('resetSettings() clears via DataSource', () async {
      // Arrange
      await repository.init();
      when(() => mockDataSource.clear()).thenAnswer((_) async {});

      // Act
      await repository.resetSettings();

      // Assert
      verify(() => mockDataSource.clear()).called(1);
    });

    test('watchSettings() returns empty stream (DataSource pattern)', () async {
      // Arrange
      await repository.init();

      // Act
      final result = repository.watchSettings();

      // Assert
      // With DataSource pattern, watchSettings returns empty stream
      expect(result, isA<Stream<BoxEvent>>());
    });
  });
}
