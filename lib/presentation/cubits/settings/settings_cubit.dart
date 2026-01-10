import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/interfaces/i_settings_repository.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final ISettingsRepository _repository;
  final SharedPreferences _prefs;
  final String _source = 'SettingsCubit';

  SettingsCubit({required ISettingsRepository repository, required SharedPreferences prefs})
    : _repository = repository,
      _prefs = prefs,
      super(SettingsInitial());

  /// 載入設定
  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final settings = _repository.getSettings();
      // 向下相容: 從 Prefs 讀取 username 如果 Settings 裡沒有
      if (settings.username.isEmpty) {
        final savedUsername = _prefs.getString(PrefKeys.username);
        if (savedUsername != null && savedUsername.isNotEmpty) {
          await _repository.updateUsername(savedUsername);
          // settings object needs refresh or manual update
          settings.username = savedUsername;
        }
      }

      final hasSeenOnboarding = _prefs.getBool('has_seen_onboarding') ?? false;

      emit(SettingsLoaded(settings: settings, hasSeenOnboarding: hasSeenOnboarding));
    } catch (e) {
      LogService.error('Failed to load settings: $e', source: _source);
      emit(SettingsError(e.toString()));
    }
  }

  /// 更新使用者名稱
  Future<void> updateUsername(String username) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      LogService.info('Update username: $username', source: _source);
      await _repository.updateUsername(username);
      // Update local prefs for backup/legacy
      await _prefs.setString(PrefKeys.username, username);

      // Reload settings to get updated object or modify current one
      final updatedSettings = _repository.getSettings();
      emit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update username: $e', source: _source);
      emit(SettingsError(e.toString()));
      // Recover state? Or just stay in Error?
      // Ideally rollback or re-emit loaded. For now error.
    }
  }

  /// 更新頭像
  Future<void> updateAvatar(String avatar) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      await _repository.updateAvatar(avatar);
      final updatedSettings = _repository.getSettings();
      emit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update avatar: $e', source: _source);
      emit(SettingsError(e.toString()));
    }
  }

  /// 同時更新 Profile (Name + Avatar)
  Future<void> updateProfile(String name, String avatar) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      LogService.info('Update profile: $name, $avatar', source: _source);
      await _repository.updateUsername(name);
      await _repository.updateAvatar(avatar);
      await _prefs.setString(PrefKeys.username, name);

      final updatedSettings = _repository.getSettings();
      emit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update profile: $e', source: _source);
      emit(SettingsError(e.toString()));
    }
  }

  /// 切換離線模式
  Future<void> toggleOfflineMode() async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;
    final newStatus = !currentState.isOfflineMode;

    try {
      await _repository.updateOfflineMode(newStatus);
      final updatedSettings = _repository.getSettings();
      emit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to toggle offline mode: $e', source: _source);
      emit(SettingsError(e.toString()));
    }
  }

  /// 更新最後同步時間
  Future<void> updateLastSyncTime(DateTime? time) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      await _repository.updateLastSyncTime(time);
      final updatedSettings = _repository.getSettings();
      emit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update last sync time: $e', source: _source);
      // Silent error for sync time?
    }
  }

  /// 完成 Onboarding
  Future<void> completeOnboarding() async {
    try {
      await _prefs.setBool('has_seen_onboarding', true);
      if (state is SettingsLoaded) {
        emit((state as SettingsLoaded).copyWith(hasSeenOnboarding: true));
      } else {
        // If not loaded yet, reload
        loadSettings();
      }
    } catch (e) {
      LogService.error('Failed to complete onboarding: $e', source: _source);
    }
  }

  /// 重置 Onboarding (Testing/Debug)
  Future<void> resetOnboarding() async {
    try {
      await _prefs.setBool('has_seen_onboarding', false);
      if (state is SettingsLoaded) {
        emit((state as SettingsLoaded).copyWith(hasSeenOnboarding: false));
      } else {
        loadSettings();
      }
    } catch (e) {
      LogService.error('Failed to reset onboarding: $e', source: _source);
    }
  }

  /// 重設身分 (Logout + Reset)
  Future<void> resetIdentity() async {
    try {
      LogService.info('Resetting identity', source: _source);
      await _repository.resetSettings();
      await _prefs.remove(PrefKeys.username);

      // Reload defaults
      loadSettings();
    } catch (e) {
      LogService.error('Failed to reset identity: $e', source: _source);
      emit(SettingsError(e.toString()));
    }
  }
}
