import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SettingsCubit settingsCubit;
  late MockSettingsRepository mockRepo;
  late MockSharedPreferences mockPrefs;
  late Settings testSettings;

  setUpAll(() {
    registerFallbackValue(AppThemeType.nature);
    registerFallbackValue(const Settings(username: '', isOfflineMode: false));
  });

  setUp(() {
    mockRepo = MockSettingsRepository();
    mockPrefs = MockSharedPreferences();
    testSettings = const Settings(username: 'TestUser', isOfflineMode: false, avatar: 'bear');

    when(() => mockRepo.getSettings()).thenAnswer((_) async => testSettings);
    when(() => mockRepo.updateUsername(any())).thenAnswer((_) async {});
    when(() => mockRepo.updateAvatar(any())).thenAnswer((_) async {});
    when(() => mockRepo.updateOfflineMode(any())).thenAnswer((_) async {});
    when(() => mockRepo.updateTheme(any())).thenAnswer((_) async {});

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    settingsCubit = SettingsCubit(mockRepo, mockPrefs);
  });

  tearDown(() {
    settingsCubit.close();
  });

  group('SettingsCubit', () {
    test('Given SettingsCubit, When executing, Then initial state is SettingsInitial', () {
      expect(settingsCubit.state, isA<SettingsInitial>());
    });

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits values from repository and prefs',
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
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: true),
      act: (cubit) async {
        when(() => mockRepo.getSettings()).thenAnswer((_) async => testSettings.copyWith(username: 'NewName'));
        await cubit.updateUsername('NewName');
      },
      verify: (_) {
        verify(() => mockRepo.updateUsername('NewName')).called(1);
        verify(() => mockPrefs.setString(PrefKeys.username, 'NewName')).called(1);
      },
      expect: () => [isA<SettingsLoaded>().having((s) => s.settings.username, 'username', 'NewName')],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleOfflineMode switches mode optimistically and then confirms',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: true),
      act: (cubit) async {
        when(() => mockRepo.getSettings()).thenAnswer((_) async => testSettings.copyWith(isOfflineMode: true));
        await cubit.toggleOfflineMode();
      },
      expect: () => [isA<SettingsLoaded>().having((s) => s.isOfflineMode, 'isOfflineMode', true)],
      verify: (_) {
        verify(() => mockRepo.updateOfflineMode(true)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'completeOnboarding updates prefs and state',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: false),
      act: (cubit) => cubit.completeOnboarding(),
      expect: () => [isA<SettingsLoaded>().having((s) => s.hasSeenOnboarding, 'hasSeenOnboarding', true)],
      verify: (_) {
        verify(() => mockPrefs.setBool('has_seen_onboarding', true)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTheme calls repo and updates state',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: true),
      act: (cubit) async {
        when(() => mockRepo.getSettings()).thenAnswer((_) async => testSettings.copyWith(theme: AppThemeType.night));
        await cubit.updateTheme(AppThemeType.night);
      },
      expect: () => [isA<SettingsLoaded>().having((s) => s.settings.theme, 'theme', AppThemeType.night)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateUsername failure stays in SettingsLoaded with transientError (no stuck error state)',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: true),
      act: (cubit) async {
        when(() => mockRepo.updateUsername(any())).thenThrow(Exception('network down'));
        await cubit.updateUsername('NewName');
      },
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.transientError, 'transientError', isNotNull)
            .having((s) => s.settings.username, 'username', 'TestUser'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'transientError is cleared after a subsequent successful update',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: true, transientError: 'previous error'),
      act: (cubit) async {
        when(() => mockRepo.getSettings()).thenAnswer((_) async => testSettings.copyWith(username: 'NewName'));
        await cubit.updateUsername('NewName');
      },
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.transientError, 'transientError', isNull)
            .having((s) => s.settings.username, 'username', 'NewName'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleOfflineMode failure rolls back to original settings with transientError',
      build: () => settingsCubit,
      seed: () => SettingsLoaded(settings: testSettings, hasSeenOnboarding: true),
      act: (cubit) async {
        when(() => mockRepo.updateOfflineMode(any())).thenThrow(Exception('disk full'));
        await cubit.toggleOfflineMode();
      },
      expect: () => [
        // 1. 樂觀更新: 立即切換為 true
        isA<SettingsLoaded>().having((s) => s.isOfflineMode, 'isOfflineMode', true),
        // 2. 失敗復原: 回到原始 false 並帶一次性錯誤
        isA<SettingsLoaded>()
            .having((s) => s.isOfflineMode, 'isOfflineMode', false)
            .having((s) => s.transientError, 'transientError', isNotNull),
      ],
    );
  });
}
