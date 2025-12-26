import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/data/repositories/interfaces/i_settings_repository.dart';
import 'package:summitmate/presentation/providers/settings_provider.dart';

// Mocks
class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSettings extends Mock implements Settings {}

void main() {
  late SettingsProvider provider;
  late MockSettingsRepository mockRepository;
  late MockSharedPreferences mockPrefs;
  late MockSettings mockSettings;

  setUp(() async {
    mockRepository = MockSettingsRepository();
    mockPrefs = MockSharedPreferences();
    mockSettings = MockSettings();

    // Reset GetIt
    await GetIt.I.reset();
    GetIt.I.registerSingleton<ISettingsRepository>(mockRepository);
    GetIt.I.registerSingleton<SharedPreferences>(mockPrefs);

    // Default mock behaviors
    when(() => mockSettings.username).thenReturn('TestUser');
    when(() => mockSettings.isOfflineMode).thenReturn(false);
    when(() => mockSettings.avatar).thenReturn('🐻');
    when(() => mockSettings.lastSyncTime).thenReturn(null);
    when(() => mockRepository.getSettings()).thenReturn(mockSettings);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('SettingsProvider Tests', () {
    test('should load settings on initialization', () {
      provider = SettingsProvider();

      expect(provider.settings, isNotNull);
      expect(provider.isLoading, isFalse);
      verify(() => mockRepository.getSettings()).called(1);
    });

    test('username should return value from settings', () {
      when(() => mockSettings.username).thenReturn('山友A');
      provider = SettingsProvider();

      expect(provider.username, equals('山友A'));
    });

    test('hasUsername should return true when username is not empty', () {
      when(() => mockSettings.username).thenReturn('山友A');
      provider = SettingsProvider();

      expect(provider.hasUsername, isTrue);
    });

    test('hasUsername should return false when username is empty', () {
      when(() => mockSettings.username).thenReturn('');
      provider = SettingsProvider();

      expect(provider.hasUsername, isFalse);
    });

    test('avatar should return value from settings', () {
      when(() => mockSettings.avatar).thenReturn('🦊');
      provider = SettingsProvider();

      expect(provider.avatar, equals('🦊'));
    });

    test('isOfflineMode should return value from settings', () {
      when(() => mockSettings.isOfflineMode).thenReturn(true);
      provider = SettingsProvider();

      expect(provider.isOfflineMode, isTrue);
    });

    test('hasSeenOnboarding should read from SharedPreferences', () {
      when(() => mockPrefs.getBool('has_seen_onboarding')).thenReturn(true);
      provider = SettingsProvider();

      expect(provider.hasSeenOnboarding, isTrue);
      verify(() => mockPrefs.getBool('has_seen_onboarding')).called(greaterThanOrEqualTo(1));
    });

    test('completeOnboarding should set SharedPreferences', () async {
      provider = SettingsProvider();

      await provider.completeOnboarding();

      verify(() => mockPrefs.setBool('has_seen_onboarding', true)).called(1);
    });

    test('resetOnboarding should clear SharedPreferences', () async {
      provider = SettingsProvider();

      await provider.resetOnboarding();

      verify(() => mockPrefs.setBool('has_seen_onboarding', false)).called(1);
    });

    test('updateUsername should call repository and refresh settings', () async {
      when(() => mockRepository.updateUsername(any())).thenAnswer((_) async {});
      provider = SettingsProvider();

      await provider.updateUsername('新名稱');

      verify(() => mockRepository.updateUsername('新名稱')).called(1);
      verify(() => mockRepository.getSettings()).called(2); // Init + after update
    });

    test('setAvatar should call repository and refresh settings', () async {
      when(() => mockRepository.updateAvatar(any())).thenAnswer((_) async {});
      provider = SettingsProvider();

      await provider.setAvatar('🐼');

      verify(() => mockRepository.updateAvatar('🐼')).called(1);
      verify(() => mockRepository.getSettings()).called(2);
    });

    test('setOfflineMode should call repository and refresh settings', () async {
      when(() => mockRepository.updateOfflineMode(any())).thenAnswer((_) async {});
      provider = SettingsProvider();

      await provider.setOfflineMode(true);

      verify(() => mockRepository.updateOfflineMode(true)).called(1);
      verify(() => mockRepository.getSettings()).called(2);
    });

    test('toggleOfflineMode should toggle current value', () async {
      when(() => mockSettings.isOfflineMode).thenReturn(false);
      when(() => mockRepository.updateOfflineMode(any())).thenAnswer((_) async {});
      provider = SettingsProvider();

      await provider.toggleOfflineMode();

      // Should toggle from false to true
      verify(() => mockRepository.updateOfflineMode(true)).called(1);
    });

    test('lastSyncTimeFormatted should return formatted string', () {
      final testTime = DateTime(2025, 12, 26, 14, 30);
      when(() => mockSettings.lastSyncTime).thenReturn(testTime);
      provider = SettingsProvider();

      expect(provider.lastSyncTimeFormatted, contains('12/26'));
      expect(provider.lastSyncTimeFormatted, contains('14:30'));
    });

    test('lastSyncTimeFormatted should return null when no sync time', () {
      when(() => mockSettings.lastSyncTime).thenReturn(null);
      provider = SettingsProvider();

      expect(provider.lastSyncTimeFormatted, isNull);
    });
  });
}
