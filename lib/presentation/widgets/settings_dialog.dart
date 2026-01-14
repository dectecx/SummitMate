import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';
import 'package:summitmate/infrastructure/tools/toast_service.dart';
import 'package:summitmate/infrastructure/tools/hive_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _nameController;
  final List<String> _avatars = ['🐻', '🦊', '🐰', '🐯', '🦁', '🐨', '🐼'];
  String _selectedAvatar = '🐻';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // Initialize state from Cubits
    final authState = context.read<AuthCubit>().state;
    final settingsState = context.read<SettingsCubit>().state;

    if (authState is AuthAuthenticated) {
      _nameController.text = authState.userName ?? '';
      _selectedAvatar = authState.avatar ?? '🐻';
    } else if (settingsState is SettingsLoaded) {
      _nameController.text = settingsState.username;
      _selectedAvatar = settingsState.avatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final authState = context.watch<AuthCubit>().state;
        final isOfflineMode = (settingsState is SettingsLoaded) ? settingsState.isOfflineMode : false;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Avatar Selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _avatars.map((avatar) {
                        final isSelected = avatar == _selectedAvatar;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatar = avatar;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.withAlpha(50) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                            ),
                            child: Text(avatar, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '暱稱',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  // User ID & Copy
                  if (authState is AuthAuthenticated && !authState.isGuest) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.fingerprint, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ID: ${authState.userId}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                          tooltip: '複製 ID',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: authState.userId));
                            ToastService.success('ID 已複製');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 16, color: Colors.grey),
                          tooltip: '分享 ID',
                          onPressed: () async {
                            // ignore: deprecated_member_use
                            await Share.share('我的 SummitMate ID 是: ${authState.userId}', subject: 'SummitMate ID');
                          },
                        ),
                      ],
                    ),
                  ],

                  // Guest mode indicator
                  if (authState is! AuthAuthenticated || authState.isGuest) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '訪客模式：資料僅儲存於本機，登入後可同步到雲端',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final newName = _nameController.text.trim();
                        if (newName.isNotEmpty) {
                          final authCubit = context.read<AuthCubit>();
                          final settingsCubit = context.read<SettingsCubit>();

                          // 1. Update Cloud (if authenticated)
                          if (authState is AuthAuthenticated && !authState.isOffline && !authState.isGuest) {
                            try {
                              final result = await authCubit.updateProfile(
                                displayName: newName,
                                avatar: _selectedAvatar,
                              );
                              if (!result.isSuccess) {
                                ToastService.error('雲端同步失敗: ${result.errorMessage}');
                              } else {
                                ToastService.success('個人資料已同步更新');
                              }
                            } catch (e) {
                              ToastService.error('更新失敗: $e');
                            }
                          }

                          // 2. Update Local
                          settingsCubit.updateProfile(newName, _selectedAvatar);

                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('儲存設定'),
                    ),
                  ),

                  const Divider(height: 32),

                  // Offline Mode
                  Card(
                    color: isOfflineMode ? Colors.orange.shade50 : null,
                    child: SwitchListTile(
                      title: const Text('離線模式'),
                      subtitle: Text(
                        isOfflineMode ? '已暫停自動同步' : '同步功能正常運作中',
                        style: TextStyle(color: isOfflineMode ? Colors.orange.shade800 : null, fontSize: 12),
                      ),
                      value: isOfflineMode,
                      onChanged: (value) async {
                        await context.read<SettingsCubit>().toggleOfflineMode();
                      },
                    ),
                  ),

                  const Divider(height: 32),

                  // Tutorial
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('重看教學引導'),
                    onTap: () {
                      Navigator.pop(context);
                      ToastService.info('請在首頁重新觸發教學');
                    },
                  ),

                  // Dev Info
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('開發資訊'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final packageInfo = await PackageInfo.fromPlatform();
                      if (context.mounted) {
                        showAboutDialog(
                          context: context,
                          applicationName: packageInfo.appName,
                          applicationVersion: '${packageInfo.version} (${packageInfo.buildNumber})',
                          applicationIcon: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(child: Text('🏔️', style: TextStyle(fontSize: 32))),
                          ),
                          children: [
                            const Text('SummitMate 是一款專為登山愛好者設計的協作 App。'),
                            const SizedBox(height: 16),
                            const Text('除錯資訊:'),
                            Text('Auth State: ${context.read<AuthCubit>().state.runtimeType}'),
                            Text('Sync State: ${context.read<SyncCubit>().state.runtimeType}'),
                            Text('Hive Initialized: ${HiveService().isInitialized}'),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
