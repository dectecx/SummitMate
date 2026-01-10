import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
// import '../providers/settings_provider.dart'; // Removed
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

/// 主頁面入口
/// 流程: 登入/註冊 → 教學引導 → 主畫面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // 1. 檢查 Auth 狀態
            if (authState is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator(), SizedBox(height: 16), Text('載入中...')],
                  ),
                ),
              );
            }

            // 2. 未登入 → 顯示登入畫面
            if (authState is AuthUnauthenticated || authState is AuthError) {
              return const LoginScreen();
            }

            // 3. 已登入但未完成 Onboarding → 顯示教學引導
            // Check based on SettingsLoaded state
            bool isOnboardingComplete = false;
            if (settingsState is SettingsLoaded) {
              // Logic: username must be set.
              // Note: SettingsCubit loads settings on app start.
              isOnboardingComplete = settingsState.username.isNotEmpty;
            } else if (settingsState is SettingsInitial || settingsState is SettingsLoading) {
              // Wait for settings to load
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!isOnboardingComplete) {
              return const OnboardingScreen();
            }

            // 4. 已登入且已完成 Onboarding → 顯示主畫面
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}
