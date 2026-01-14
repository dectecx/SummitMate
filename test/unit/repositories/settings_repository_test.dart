import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/data/repositories/settings_repository.dart';
import 'package:summitmate/infrastructure/tools/hive_service.dart';

// Mocks
class MockHiveService extends Mock implements HiveService {}

class MockBox<T> extends Mock implements Box<T> {}

class MockSettings extends Mock implements Settings {}

void main() {
  late SettingsRepository repository;
  late MockHiveService mockHiveService;
  late MockBox<Settings> mockBox;

  const boxName = 'settings';
  const settingsKey = 'app_settings';

  setUpAll(() {
    registerFallbackValue(Settings());
  });

  setUp(() {
    mockHiveService = MockHiveService();
    mockBox = MockBox<Settings>();
    mockBox = MockBox<Settings>();

    // Inject mock via constructor
    repository = SettingsRepository(hiveService: mockHiveService);

    // Default openBox behavior
    when(() => mockHiveService.openBox<Settings>(any())).thenAnswer((_) async => mockBox);

    // Mock Box.isOpen to true by default for easier testing
    when(() => mockBox.isOpen).thenReturn(true);
  });

  group('SettingsRepository', () {
    test('init() should open settings box via HiveService', () async {
      // Act
      await repository.init();

      // Assert
      verify(() => mockHiveService.openBox<Settings>(boxName)).called(1);
    });

    test('getSettings() returns existing settings if present', () async {
      // Arrange
      await repository.init();
      final settings = Settings(username: 'Test User');
      when(() => mockBox.get(settingsKey)).thenReturn(settings);

      // Act
      final result = repository.getSettings();

      // Assert
      expect(result, equals(settings));
      expect(result.username, 'Test User');
      verify(() => mockBox.get(settingsKey)).called(1);
    });

    test('getSettings() creates default settings if missing', () async {
      // Arrange
      await repository.init();
      when(() => mockBox.get(settingsKey)).thenReturn(null);
      when(() => mockBox.put(settingsKey, any())).thenAnswer((_) async => {});

      // Act
      final result = repository.getSettings();

      // Assert
      expect(result.username, ''); // Default
      expect(result.avatar, '🐻'); // Default
      verify(() => mockBox.get(settingsKey)).called(1);
      verify(() => mockBox.put(settingsKey, any())).called(1);
    });

    test('updateUsername() updates settings and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockBox.get(settingsKey)).thenReturn(mockSettings);
      when(() => mockSettings.save()).thenAnswer((_) async => {});

      // Need to stub setter if Mocktail doesn't automatically tracking property sets?
      // Mocktail mocks methods. Getters/Setters are methods.
      // But for simple properties on a Mock object, behavior is tricky.
      // Usually we verify the setter was called.
      // when(() => mockSettings.username = any()).thenReturn(null); // Setters return void/null

      // Actually, since Settings is a data class, maybe using a real Settings object is better
      // providing we mock the save() method or if save() works.
      // But Settings extends HiveObject. save() relies on box being attached.

      // If we use MockSettings, we can verify the setter call.

      // Act
      await repository.updateUsername('New Name');

      // Assert
      verify(() => mockSettings.username = 'New Name').called(1);
      verify(() => mockSettings.save()).called(1);
    });

    test('updateOfflineMode() updates value and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockBox.get(settingsKey)).thenReturn(mockSettings);
      when(() => mockSettings.save()).thenAnswer((_) async => {});

      // Act
      await repository.updateOfflineMode(true);

      // Assert
      verify(() => mockSettings.isOfflineMode = true).called(1);
      verify(() => mockSettings.save()).called(1);
    });

    test('updateAvatar() updates avatar and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockBox.get(settingsKey)).thenReturn(mockSettings);
      when(() => mockSettings.save()).thenAnswer((_) async => {});

      // Act
      await repository.updateAvatar('🦊');

      // Assert
      verify(() => mockSettings.avatar = '🦊').called(1);
      verify(() => mockSettings.save()).called(1);
    });

    test('updateLastSyncTime() updates time and saves', () async {
      // Arrange
      await repository.init();
      final mockSettings = MockSettings();
      when(() => mockBox.get(settingsKey)).thenReturn(mockSettings);
      when(() => mockSettings.save()).thenAnswer((_) async => {});
      final time = DateTime(2023, 1, 1);

      // Act
      await repository.updateLastSyncTime(time);

      // Assert
      verify(() => mockSettings.lastSyncTime = time).called(1);
      verify(() => mockSettings.save()).called(1);
    });

    test('resetSettings() clears the box', () async {
      // Arrange
      await repository.init();
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      // Act
      await repository.resetSettings();

      // Assert
      verify(() => mockBox.clear()).called(1);
    });

    test('watchSettings() returns box stream', () async {
      // Arrange
      await repository.init();
      final stream = Stream<BoxEvent>.empty();
      when(() => mockBox.watch(key: settingsKey)).thenAnswer((_) => stream);

      // Act
      final result = repository.watchSettings();

      // Assert
      expect(result, equals(stream));
      verify(() => mockBox.watch(key: settingsKey)).called(1);
    });
  });
}
