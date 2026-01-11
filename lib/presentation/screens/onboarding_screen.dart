import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/settings/settings_cubit.dart';
import '../../infrastructure/tools/toast_service.dart';

/// Onboarding 畫面 (新手引導)
///
/// 用於初次啟動 App 時，讓使用者設定 [SettingsCubit] 中的基本資料 (暱稱、頭像)。
/// 設定完成後會自動導向主畫面。
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  String _selectedAvatar = '🐻';
  final List<String> _avatars = ['🐻', '🦊', '🐰', '🦁', '🐨', '🐯', '🐼', '🐮'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ToastService.error('請輸入暱稱');
      return;
    }

    try {
      await context.read<SettingsCubit>().updateProfile(name, _selectedAvatar);
      // Configured -> HomeScreen will automatically switch to MainNavigationScreen
    } catch (e) {
      ToastService.error('設定失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歡迎使用 SummitMate')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('初次見面！請設定您的檔案', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            const Text('選擇代表您的頭像'),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map((avatar) {
                final isSelected = _selectedAvatar == avatar;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = avatar),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Text(avatar, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '您的暱稱',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(onPressed: _submit, child: const Text('開始使用')),
            ),
          ],
        ),
      ),
    );
  }
}
