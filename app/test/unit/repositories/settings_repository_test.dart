import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/data/repositories/settings_repository.dart';
import 'package:summitmate/data/datasources/interfaces/i_settings_local_data_source.dart';

// Mocks
class MockSettingsLocalDataSource extends Mock implements ISettingsLocalDataSource {}

void main() {
  late SettingsRepository repository;
  late MockSettingsLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(Settings());
  });

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();

    // Default behaviors
    when(() => mockDataSource.getSettings()).thenReturn(null);
    when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

    // Inject mock via constructor (automatically calls getSettings)
    repository = SettingsRepository(localDataSource: mockDataSource);
  });

  group('SettingsRepository', () {
    test('constructor should preload settings from DataSource', () async {
      // Assert
      verify(() => mockDataSource.getSettings()).called(1);
    });

    test('getSettings() returns existing settings if present', () async {
      // Arrange
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
      final settings = Settings();
      when(() => mockDataSource.getSettings()).thenReturn(settings);
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

      // Act
      await repository.updateUsername('New Name');

      // Assert
      verify(
        () => mockDataSource.saveSettings(any(that: isA<Settings>().having((s) => s.username, 'username', 'New Name'))),
      ).called(1);
    });

    test('updateOfflineMode() updates value and saves', () async {
      // Arrange
      final settings = Settings();
      when(() => mockDataSource.getSettings()).thenReturn(settings);
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

      // Act
      await repository.updateOfflineMode(true);

      // Assert
      verify(
        () => mockDataSource.saveSettings(
          any(that: isA<Settings>().having((s) => s.isOfflineMode, 'isOfflineMode', true)),
        ),
      ).called(1);
    });

    test('updateAvatar() updates avatar and saves', () async {
      // Arrange
      final settings = Settings();
      when(() => mockDataSource.getSettings()).thenReturn(settings);
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

      // Act
      await repository.updateAvatar('🦊');

      // Assert
      verify(
        () => mockDataSource.saveSettings(any(that: isA<Settings>().having((s) => s.avatar, 'avatar', '🦊'))),
      ).called(1);
    });

    test('updateLastSyncTime() updates time and saves', () async {
      // Arrange
      final settings = Settings();
      when(() => mockDataSource.getSettings()).thenReturn(settings);
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});
      final time = DateTime(2023, 1, 1);

      // Act
      await repository.updateLastSyncTime(time);

      // Assert
      verify(
        () =>
            mockDataSource.saveSettings(any(that: isA<Settings>().having((s) => s.lastSyncTime, 'lastSyncTime', time))),
      ).called(1);
    });

    test('resetSettings() clears via DataSource', () async {
      // Arrange
      when(() => mockDataSource.clear()).thenAnswer((_) async {});

      // Act
      await repository.resetSettings();

      // Assert
      verify(() => mockDataSource.clear()).called(1);
    });

    test('watchSettings() returns empty stream (DataSource pattern)', () async {
      // Arrange
      // Act
      final result = repository.watchSettings();

      // Assert
      // With DataSource pattern, watchSettings returns empty stream
      expect(result, isA<Stream<BoxEvent>>());
    });
  });
}
