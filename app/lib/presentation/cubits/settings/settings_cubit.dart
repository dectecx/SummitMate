import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/core/core.dart';
import '../../../domain/repositories/i_settings_repository.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'settings_state.dart';

@injectable
class SettingsCubit extends Cubit<SettingsState> with SafeEmitMixin<SettingsState> {
  final ISettingsRepository _repository;
  final SharedPreferences _prefs;
  final String _source = 'SettingsCubit';

  SettingsCubit(this._repository, this._prefs) : super(SettingsInitial());

  /// 載入設定
  Future<void> loadSettings() async {
    safeEmit(SettingsLoading());
    try {
      final settings = await _repository.getSettings();
      // 向下相容: 從 Prefs 讀取 username 如果 Settings 裡沒有
      if (settings.username.isEmpty) {
        final savedUsername = _prefs.getString(PrefKeys.username);
        if (savedUsername != null && savedUsername.isNotEmpty) {
          await _repository.updateUsername(savedUsername);
          // 重新載入設定
          final updatedSettings = await _repository.getSettings();
          safeEmit(
            SettingsLoaded(
              settings: updatedSettings,
              hasSeenOnboarding: _prefs.getBool('has_seen_onboarding') ?? false,
            ),
          );
          return;
        }
      }

      final hasSeenOnboarding = _prefs.getBool('has_seen_onboarding') ?? false;

      safeEmit(SettingsLoaded(settings: settings, hasSeenOnboarding: hasSeenOnboarding));
    } catch (e) {
      LogService.error('Failed to load settings: $e', source: _source);
      safeEmit(SettingsError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新使用者名稱
  ///
  /// [username] 新的使用者名稱
  Future<void> updateUsername(String username) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      LogService.info('Update username: $username', source: _source);
      await _repository.updateUsername(username);
      // 更新本地 Prefs 作為備份/其餘用途
      await _prefs.setString(PrefKeys.username, username);

      // 重新載入設定以取得更新後的物件
      final updatedSettings = await _repository.getSettings();
      safeEmit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update username: $e', source: _source);
      // 復原至更新前的 Loaded 狀態並附帶一次性錯誤，避免卡在 SettingsError
      safeEmit(currentState.copyWith(transientError: AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新頭像
  ///
  /// [avatar] 新的頭像 URL
  Future<void> updateAvatar(String avatar) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      await _repository.updateAvatar(avatar);
      final updatedSettings = await _repository.getSettings();
      safeEmit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update avatar: $e', source: _source);
      safeEmit(currentState.copyWith(transientError: AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 同時更新 Profile (Name + Avatar)
  ///
  /// [name] 使用者名稱
  /// [avatar] 頭像 URL
  Future<void> updateProfile(String name, String avatar) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      LogService.info('Update profile: $name, $avatar', source: _source);
      await _repository.updateUsername(name);
      await _repository.updateAvatar(avatar);
      await _prefs.setString(PrefKeys.username, name);

      final updatedSettings = await _repository.getSettings();
      safeEmit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update profile: $e', source: _source);
      safeEmit(currentState.copyWith(transientError: AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 切換離線模式
  Future<void> toggleOfflineMode() async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;
    final newStatus = !currentState.isOfflineMode;

    // 1. 樂觀更新 UI (立刻發送新狀態，不等待資料庫寫入)
    final tempSettings = currentState.settings.copyWith(isOfflineMode: newStatus);
    safeEmit(currentState.copyWith(settings: tempSettings));

    try {
      // 2. 執行實際儲存
      await _repository.updateOfflineMode(newStatus);
      // 3. 儲存後再次確認狀態 (以防 repository 內部有其他邏輯或需要同步最新物件)
      final updatedSettings = await _repository.getSettings();
      safeEmit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to toggle offline mode: $e', source: _source);
      // 4. 發生錯誤時復原樂觀更新前的狀態，並附帶一次性錯誤（不離開 SettingsLoaded）
      safeEmit(currentState.copyWith(transientError: '狀態更新失敗: ${AppErrorHandler.getUserMessage(e)}'));
    }
  }

  /// 更新最後同步時間
  ///
  /// [time] 同步時間
  Future<void> updateLastSyncTime(DateTime? time) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      await _repository.updateLastSyncTime(time);
      final updatedSettings = await _repository.getSettings();
      safeEmit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update last sync time: $e', source: _source);
      // 同步時間更新失敗可靜默處理
    }
  }

  /// 完成 Onboarding
  Future<void> completeOnboarding() async {
    try {
      await _prefs.setBool('has_seen_onboarding', true);
      if (state is SettingsLoaded) {
        safeEmit((state as SettingsLoaded).copyWith(hasSeenOnboarding: true));
      } else {
        // 若尚未載入，則進行載入
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
        safeEmit((state as SettingsLoaded).copyWith(hasSeenOnboarding: false));
      } else {
        loadSettings();
      }
    } catch (e) {
      LogService.error('Failed to reset onboarding: $e', source: _source);
    }
  }

  /// 更新主題
  ///
  /// [theme] 新的主題
  Future<void> updateTheme(AppThemeType theme) async {
    if (state is! SettingsLoaded) return;
    final currentState = state as SettingsLoaded;

    try {
      LogService.info('Update theme: $theme', source: _source);

      await _repository.updateTheme(theme);
      final updatedSettings = await _repository.getSettings();

      safeEmit(currentState.copyWith(settings: updatedSettings));
    } catch (e) {
      LogService.error('Failed to update theme: $e', source: _source);
      safeEmit(currentState.copyWith(transientError: AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 重設身分 (Logout + Reset)
  Future<void> resetIdentity() async {
    final previousState = state;
    try {
      LogService.info('Resetting identity', source: _source);
      await _repository.resetSettings();
      await _prefs.remove(PrefKeys.username);

      // 重新載入預設值
      loadSettings();
    } catch (e) {
      LogService.error('Failed to reset identity: $e', source: _source);
      // 若先前已載入，復原該狀態並附帶一次性錯誤，避免卡在 SettingsError
      if (previousState is SettingsLoaded) {
        safeEmit(previousState.copyWith(transientError: AppErrorHandler.getUserMessage(e)));
      } else {
        safeEmit(SettingsError(AppErrorHandler.getUserMessage(e)));
      }
    }
  }
}
