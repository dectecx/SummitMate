import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

/// 主頁面 (帶 Onboarding 檢查)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // 檢查是否已完成 Onboarding (有設定名稱)
        final isConfigured = settings.username.isNotEmpty;

        if (!isConfigured) {
          return const OnboardingScreen();
        }

        return const MainNavigationScreen();
      },
    );
  }
}
