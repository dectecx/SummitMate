import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/settings_repository.dart';
import 'package:summitmate/data/datasources/interfaces/i_settings_local_data_source.dart';

// Mocks
class MockSettingsLocalDataSource extends Mock implements ISettingsLocalDataSource {}

class FakeSettings extends Fake implements Settings {}

void main() {
  late SettingsRepository repository;
  late MockSettingsLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeSettings());
  });

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();

    // Default behaviors
    when(() => mockDataSource.getSettings()).thenAnswer((_) async => null);
    when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

    repository = SettingsRepository(localDataSource: mockDataSource);
  });

  group('SettingsRepository', () {
    test('getSettings() returns existing settings if present', () async {
      // Arrange
      const model = Settings(username: 'Test User');
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => model);

      // Act
      final result = await repository.getSettings();

      // Assert
      expect(result.username, 'Test User');
    });

    test('getSettings() creates default settings if missing', () async {
      // Arrange
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => null);
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.getSettings();

      // Assert
      expect(result.username, ''); // Default
      expect(result.avatar, '🐻'); // Default
      verify(() => mockDataSource.saveSettings(any())).called(1);
    });

    test('updateUsername() updates settings and saves', () async {
      // Arrange
      const model = Settings();
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => model);
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
      const model = Settings();
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => model);
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
      const model = Settings();
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => model);
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
      const model = Settings();
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => model);
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
  });
}
