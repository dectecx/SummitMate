import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:summitmate/data/repositories/interfaces/i_settings_repository.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSettings extends Mock implements Settings {}

void main() {
  group('SettingsCubit', () {
    late SettingsCubit settingsCubit;
    late MockSettingsRepository mockRepo;
    late MockSharedPreferences mockPrefs;
    late MockSettings mockSettings;

    setUp(() {
      mockRepo = MockSettingsRepository();
      mockPrefs = MockSharedPreferences();
      mockSettings = MockSettings();

      when(() => mockSettings.username).thenReturn('TestUser');
      when(() => mockSettings.isOfflineMode).thenReturn(false);
      when(() => mockSettings.avatar).thenReturn('bear');
      when(() => mockRepo.getSettings()).thenReturn(mockSettings);
      when(() => mockRepo.updateUsername(any())).thenAnswer((_) async {});
      when(() => mockRepo.updateAvatar(any())).thenAnswer((_) async {});
      when(() => mockRepo.updateOfflineMode(any())).thenAnswer((_) async {});

      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      settingsCubit = SettingsCubit(repository: mockRepo, prefs: mockPrefs);
    });

    tearDown(() {
      settingsCubit.close();
    });

    test('initial state is SettingsInitial', () {
      expect(settingsCubit.state, isA<SettingsInitial>());
    });

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits values from repository',
      build: () => settingsCubit,
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<SettingsLoading>(),
        isA<SettingsLoaded>().having((s) => s.settings.username, 'username', 'TestUser'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateUsername calls repo and emits updated state',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: mockSettings, hasSeenOnboarding: true),
      act: (cubit) => cubit.updateUsername('NewName'),
      verify: (_) {
        verify(() => mockRepo.updateUsername('NewName')).called(1);
        verify(() => mockPrefs.setString('username', 'NewName')).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleOfflineMode switches mode',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: mockSettings, hasSeenOnboarding: true),
      act: (cubit) => cubit.toggleOfflineMode(),
      verify: (_) {
        verify(() => mockRepo.updateOfflineMode(true)).called(1);
      },
    );
  });
}
