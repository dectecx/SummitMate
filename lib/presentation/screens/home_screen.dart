import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

/// 主頁面入口
/// 流程: 登入/註冊 → 教學引導 → 主畫面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, child) {
        // 1. 檢查 Auth 狀態
        if (authProvider.state == AuthState.loading) {
          // 正在載入 Session
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
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // 3. 已登入但未完成 Onboarding → 顯示教學引導
        final isOnboardingComplete = settingsProvider.username.isNotEmpty;
        if (!isOnboardingComplete) {
          return const OnboardingScreen();
        }

        // 4. 已登入且已完成 Onboarding → 顯示主畫面
        return const MainNavigationScreen();
      },
    );
  }
}
