import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/theme.dart';
import 'core/di.dart';
import 'core/constants.dart';
import 'services/toast_service.dart';
import 'services/log_service.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/itinerary_provider.dart';
import 'presentation/providers/message_provider.dart';
import 'presentation/providers/gear_provider.dart';
import 'presentation/providers/meal_provider.dart';
import 'presentation/screens/map_viewer_screen.dart';
import 'presentation/screens/meal_planner_screen.dart';
import 'presentation/widgets/itinerary_edit_dialog.dart';

void main() async {
  // 確保 Flutter Binding 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化依賴注入
  await setupDependencies();

  runApp(const SummitMateApp());
}

/// SummitMate 主應用程式
class SummitMateApp extends StatelessWidget {
  const SummitMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => GearProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
      ],
      child: _buildMaterialApp(),
    );
  }

  Widget _buildMaterialApp() {
    return MaterialApp(
      title: 'SummitMate',
      debugShowCheckedModeBanner: false,

      // Toast 訊息的 key
      scaffoldMessengerKey: ToastService.messengerKey,

      // 大自然主題配色
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // 初始頁面
      home: const _HomeScreen(),
    );
  }
}

/// 主頁面 (帶 Onboarding 檢查)
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 若尚未設定使用者名稱，顯示 Onboarding
        if (!settings.hasUsername) {
          return const _OnboardingScreen();
        }

        return const _MainNavigationScreen();
      },
    );
  }
}

/// Onboarding 畫面 (設定暱稱與頭像)
class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen();

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String _selectedAvatar = '🐻';

  final List<String> _avatars = ['🐻', '🦊', '🦁', '🐯', '🐨', '🐵', '🐧', '🦉', '🐺', '🐗'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() => _isSubmitting = true);

    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.setAvatar(_selectedAvatar);
    await settingsProvider.updateUsername(username);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('歡迎使用 SummitMate', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('請設定您的登山者形象', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),

              // Avatar Preview & Selector
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(_selectedAvatar, style: const TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 24),

              // Emoji Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _avatars.map((emoji) {
                  final isSelected = _selectedAvatar == emoji;
                  return InkWell(
                    onTap: () => setState(() => _selectedAvatar = emoji),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Username Input
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '您的暱稱',
                  hintText: '例：山林小精靈',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('開始使用'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主導覽畫面 (Bottom Navigation)
class _MainNavigationScreen extends StatefulWidget {
  const _MainNavigationScreen();

  @override
  State<_MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<_MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 連接同步回調
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider = context.read<MessageProvider>();
      final itineraryProvider = context.read<ItineraryProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      // 行程同步完成時，通知 ItineraryProvider 重載
      messageProvider.onItinerarySynced = () {
        itineraryProvider.reload();
      };

      // 同步完成時，更新 lastSyncTime
      messageProvider.onSyncComplete = (syncedAt) {
        settingsProvider.updateLastSyncTime(syncedAt);
      };

      // 檢查首次同步
      _checkFirstTimeSync(context, settingsProvider);
    });
  }

  void _checkFirstTimeSync(BuildContext context, SettingsProvider settings) {
    if (settings.lastSyncTime == null && !settings.isOfflineMode) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('歡迎來到 SummitMate'),
          content: const Text(
            '為了讓您有最佳體驗，建議您先同步最新的行程與留言資料。\n\n'
            '這只需要一點點時間。',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('稍後')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<MessageProvider>().sync();
              },
              child: const Text('立即同步'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 ItineraryProvider 以控制 AppBar/FAB
    return Consumer<ItineraryProvider>(
      builder: (context, itineraryProvider, child) {
        return Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            final scaffold = Scaffold(
              appBar: AppBar(
                title: const Text('SummitMate 山友'),
                bottom: messageProvider.isSyncing
                    ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator())
                    : null,
                actions: [
                  // Tab 0: 行程編輯與地圖
                  if (_currentIndex == 0) ...[
                    IconButton(
                      icon: Icon(itineraryProvider.isEditMode ? Icons.check : Icons.edit),
                      tooltip: itineraryProvider.isEditMode ? '完成' : '編輯行程',
                      onPressed: () => itineraryProvider.toggleEditMode(),
                    ),
                    if (itineraryProvider.isEditMode)
                      IconButton(
                        icon: const Icon(Icons.cloud_upload_outlined),
                        tooltip: '上傳至雲端',
                        onPressed: () => _handleCloudUpload(context, itineraryProvider),
                      ),
                    if (!itineraryProvider.isEditMode)
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        tooltip: '查看地圖',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewerScreen()));
                        },
                      ),
                  ],
                  // 同步按鈕
                  IconButton(
                    icon: messageProvider.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync),
                    onPressed: messageProvider.isSyncing ? null : () => messageProvider.sync(),
                    tooltip: '同步資料',
                  ),
                  // 設定按鈕
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showSettingsDialog(context),
                    tooltip: '設定',
                  ),
                ],
              ),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildTabContent(_currentIndex),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                  // 切換分頁時關閉編輯模式
                  if (itineraryProvider.isEditMode) {
                    itineraryProvider.toggleEditMode();
                  }
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.schedule), selectedIcon: Icon(Icons.schedule), label: '行程'),

                  NavigationDestination(
                    icon: Icon(Icons.forum_outlined),
                    selectedIcon: Icon(Icons.forum),
                    label: '留言板',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.backpack_outlined),
                    selectedIcon: Icon(Icons.backpack),
                    label: '裝備',
                  ),
                ],
              ),
              floatingActionButton: (_currentIndex == 0 && itineraryProvider.isEditMode)
                  ? FloatingActionButton(
                      onPressed: () => _showAddItineraryDialog(context, itineraryProvider),
                      child: const Icon(Icons.add),
                    )
                  : null,
            );

            // [Web Support] Responsive Wrapper
            // 在寬螢幕上限制最大寬度，置中顯示，維持手機版面比例
            return Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: scaffold),
            );
          },
        );
      },
    );
  }

  /// 建立對應頁籤內容 (帶 key 以支援 AnimatedSwitcher)
  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const _ItineraryTab(key: ValueKey(0));
      case 1:
        return const _CollaborationTab(key: ValueKey(1));
      case 2:
        return const _GearTab(key: ValueKey(2));
      case 3:
        return const _InfoTab(key: ValueKey(3));
      default:
        return const _ItineraryTab(key: ValueKey(0));
    }
  }

  void _showAddItineraryDialog(BuildContext context, ItineraryProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ItineraryEditDialog(defaultDay: provider.selectedDay),
    );

    if (result != null) {
      provider.addItem(
        day: provider.selectedDay,
        name: result['name'],
        estTime: result['estTime'],
        altitude: result['altitude'],
        distance: result['distance'],
        note: result['note'],
      );
    }
  }

  void _showSettingsDialog(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settingsProvider.username);

    PackageInfo? packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 離線模式 (獨立於表單上方)
              Card(
                color: settingsProvider.isOfflineMode ? Colors.orange.shade50 : null,
                child: SwitchListTile(
                  title: const Text('離線模式'),
                  subtitle: Text(
                    settingsProvider.isOfflineMode ? '已暫停自動同步' : '同步功能正常運作中',
                    style: TextStyle(
                      color: settingsProvider.isOfflineMode ? Colors.orange.shade800 : null,
                      fontSize: 12,
                    ),
                  ),
                  value: settingsProvider.isOfflineMode,
                  onChanged: (value) async {
                    await settingsProvider.setOfflineMode(value);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '暱稱',
                  prefixIcon: const Icon(Icons.person),
                  // 顯示當前頭像
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      radius: 16,
                      child: Text(settingsProvider.avatar, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),

              const Divider(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      packageInfo != null ? '版本 ${packageInfo.version} (${packageInfo.buildNumber})' : '版本資訊讀取中...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              Text(
                '上次同步: ${settingsProvider.lastSyncTimeFormatted ?? "尚未同步"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLogViewer(context);
                  },
                  icon: const Icon(Icons.article_outlined, size: 18),
                  label: const Text('查看日誌'),
                ),
              ),

              const SizedBox(height: 8),
              // 登出按鈕
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('重設身分'),
                        content: const Text('確定要清除所有身分資料並回到初始畫面嗎？\n(這不會刪除已儲存的行程與留言)'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('重設'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      Navigator.pop(context); // 關閉設定對話框
                      await settingsProvider.resetIdentity();
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                  label: const Text('重設身分 (登出)', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  settingsProvider.updateUsername(newName);
                }
                Navigator.pop(context);
              },
              child: const Text('儲存詳細資料'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCloudUpload(BuildContext context, ItineraryProvider provider) async {
    // 檢查離線模式
    final settingsIsOffline = context.read<SettingsProvider>().isOfflineMode;
    if (settingsIsOffline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 目前為離線模式，無法上傳行程'), backgroundColor: Colors.orange));
      return;
    }

    // 1. 顯示檢查中 Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. 檢查衝突
    final hasConflict = await provider.checkConflict();

    if (!context.mounted) return;
    Navigator.pop(context); // 關閉 Loading

    if (hasConflict) {
      // 3. 有衝突，顯示警告
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ 雲端資料衝突'),
          content: const Text(
            '雲端上的行程資料與您目前的版本不同。\n\n'
            '若選擇「強制覆蓋」，雲端的資料將被您的版本完全取代。\n'
            '確定要繼續嗎？',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // 關閉 Dialog
                provider.uploadToCloud(); // 執行上傳
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('強制覆蓋'),
            ),
          ],
        ),
      );
    } else {
      // 4. 無衝突，直接確認上傳
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('上傳行程'),
          content: const Text('確定將目前的行程計畫上傳至雲端嗎？此操作將覆寫雲端資料。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                provider.uploadToCloud();
              },
              child: const Text('上傳'),
            ),
          ],
        ),
      );
    }
  }

  void _showLogViewer(BuildContext context) {
    final logs = LogService.getRecentLogs(count: 100);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 標題列
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('應用日誌 (${logs.length})', style: Theme.of(context).textTheme.titleLarge),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          ToastService.info('正在上傳...');
                          final (success, message) = await LogService.uploadToCloud();
                          if (success) {
                            ToastService.success(message);
                          } else {
                            ToastService.error(message);
                          }
                        },
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: const Text('上傳'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await LogService.clearAll();
                          Navigator.pop(context);
                          ToastService.info('日誌已清除');
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('清除'),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 日誌列表
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('暫無日誌'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          dense: true,
                          leading: _getLogIcon(log.level),
                          title: Text(
                            log.message,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${log.formatted.substring(0, 8)} ${log.source ?? ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return const Icon(Icons.bug_report, size: 18, color: Colors.grey);
      case LogLevel.info:
        return const Icon(Icons.info_outline, size: 18, color: Colors.blue);
      case LogLevel.warning:
        return const Icon(Icons.warning_amber, size: 18, color: Colors.orange);
      case LogLevel.error:
        return const Icon(Icons.error_outline, size: 18, color: Colors.red);
    }
  }
}

/// Tab 1: 行程頁 (Placeholder - Phase 5 完整實作)
class _ItineraryTab extends StatelessWidget {
  const _ItineraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.allItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('尚無行程資料'),
                Text('請點擊協作頁同步取得行程'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 天數切換
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'D0', label: Text('D0')),
                  ButtonSegment(value: 'D1', label: Text('D1')),
                  ButtonSegment(value: 'D2', label: Text('D2')),
                ],
                selected: {provider.selectedDay},
                onSelectionChanged: (selected) {
                  provider.selectDay(selected.first);
                },
              ),
            ),
            // 行程列表
            Expanded(
              child: ListView.builder(
                itemCount: provider.currentDayItems.length,
                itemBuilder: (context, index) {
                  final item = provider.currentDayItems[index];
                  // 計算累積距離
                  double cumulativeDistance = 0;
                  for (int i = 0; i <= index; i++) {
                    cumulativeDistance += provider.currentDayItems[i].distance;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isCheckedIn ? Colors.green : Theme.of(context).colorScheme.primary,
                        child: item.isCheckedIn
                            ? const Icon(Icons.check, color: Colors.white)
                            : Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.isCheckedIn
                                ? '✓ 打卡: ${item.actualTime?.hour.toString().padLeft(2, '0')}:${item.actualTime?.minute.toString().padLeft(2, '0')}'
                                : '預計: ${item.estTime}',
                            style: TextStyle(color: item.isCheckedIn ? Colors.green : null),
                          ),
                          Text(
                            '海拔 ${item.altitude}m  |  累計 ${cumulativeDistance.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: provider.isEditMode
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _confirmDelete(context, provider, item.key),
                            )
                          : (item.note.isNotEmpty ? const Icon(Icons.info_outline, size: 20) : null),
                      onTap: () {
                        if (provider.isEditMode) {
                          _showEditDialog(context, provider, item);
                        } else {
                          _showCheckInDialog(context, item, provider);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ItineraryProvider provider, dynamic key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除行程'),
        content: const Text('確定要刪除此行程節點嗎？此動作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.deleteItem(key);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ItineraryProvider provider, dynamic item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ItineraryEditDialog(item: item, defaultDay: provider.selectedDay),
    );

    if (result != null) {
      // 保留原有屬性，僅更新變更部分 (但 Repository 是覆蓋)
      // 需要建構完整的 ItineraryItem
      final updatedItem = item.copyWith(
        name: result['name'],
        estTime: result['estTime'],
        altitude: result['altitude'],
        distance: result['distance'],
        note: result['note'],
      );

      provider.updateItem(item.key, updatedItem);
    }
  }

  void _showCheckInDialog(BuildContext context, dynamic item, ItineraryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題列
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.terrain, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const Divider(height: 24),
            // 詳情資訊
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.schedule, label: '預計 ${item.estTime}'),
                _InfoChip(icon: Icons.landscape, label: '海拔 ${item.altitude}m'),
                _InfoChip(icon: Icons.straighten, label: '距離 ${item.distance} km'),
              ],
            ),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(item.note, style: const TextStyle(fontSize: 14)),
              ),
            ],
            const Divider(height: 24),
            // 打卡選項
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('現在時間打卡'),
              onTap: () {
                provider.checkInNow(item.key);
                ToastService.success('已打卡：${item.name}');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('指定時間'),
              onTap: () async {
                Navigator.pop(context);
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) {
                  final now = DateTime.now();
                  provider.checkIn(item.key, DateTime(now.year, now.month, now.day, time.hour, time.minute));
                  ToastService.success('已打卡：${item.name}');
                }
              },
            ),
            if (item.isCheckedIn)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('清除打卡'),
                onTap: () {
                  provider.clearCheckIn(item.key);
                  ToastService.info('已清除打卡');
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 資訊 Chip
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label), visualDensity: VisualDensity.compact);
  }
}

/// Tab 2: 協作頁
class _CollaborationTab extends StatelessWidget {
  const _CollaborationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MessageProvider, SettingsProvider>(
      builder: (context, messageProvider, settingsProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              // 分類切換 + 同步按鈕
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'Important',
                            label: Text('重要'),
                            icon: Icon(Icons.campaign_outlined),
                          ),
                          ButtonSegment(
                            value: 'Chat',
                            label: Text('討論'),
                            icon: Icon(Icons.chat_bubble_outline),
                          ),
                          ButtonSegment(
                            value: 'Gear',
                            label: Text('裝備'),
                            icon: Icon(Icons.backpack_outlined),
                          ),
                        ],
                        selected: {messageProvider.selectedCategory},
                        onSelectionChanged: (selected) {
                          messageProvider.selectCategory(selected.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 留言列表
              Expanded(
                child: messageProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messageProvider.currentCategoryMessages.isEmpty
                    ? const Center(child: Text('尚無留言，點擊右下角新增'))
                    : ListView.builder(
                        itemCount: messageProvider.currentCategoryMessages.length,
                        itemBuilder: (context, index) {
                          final msg = messageProvider.currentCategoryMessages[index];
                          final replies = messageProvider.getReplies(msg.uuid);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(msg.avatar),
                              ),
                              title: Text(msg.content),
                              subtitle: Text('${msg.user} · ${msg.timestamp.month}/${msg.timestamp.day}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (replies.isNotEmpty)
                                    Text('${replies.length}', style: Theme.of(context).textTheme.bodySmall),
                                  IconButton(
                                    icon: const Icon(Icons.reply, size: 20),
                                    onPressed: settingsProvider.isOfflineMode
                                        ? null
                                        : () => _showReplyDialog(
                                            context,
                                            messageProvider,
                                            settingsProvider.username,
                                            settingsProvider.avatar,
                                            msg.uuid,
                                          ),
                                    tooltip: '回覆',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () => _confirmDelete(context, messageProvider, msg.uuid),
                                    tooltip: '刪除',
                                  ),
                                ],
                              ),
                              children: replies
                                  .map(
                                    (reply) => ListTile(
                                      leading: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: Text(reply.avatar, style: const TextStyle(fontSize: 12)),
                                      ),
                                      title: Text(reply.content),
                                      subtitle: Text('${reply.user} · ${reply.timestamp.month}/${reply.timestamp.day}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        onPressed: () => _confirmDelete(context, messageProvider, reply.uuid),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: settingsProvider.isOfflineMode ? Colors.grey : null,
            onPressed: settingsProvider.isOfflineMode
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ 離線模式下無法新增留言')));
                  }
                : () => _showAddMessageDialog(
                    context,
                    messageProvider,
                    settingsProvider.username,
                    settingsProvider.avatar,
                    null,
                  ),
            child: const Icon(Icons.add_comment),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, MessageProvider provider, String uuid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此留言嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              provider.deleteMessage(uuid);
              Navigator.pop(context);
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showAddMessageDialog(
    BuildContext context,
    MessageProvider provider,
    String username,
    String avatar,
    String? parentId,
  ) {
    final contentController = TextEditingController();
    final isReply = parentId != null;

    showDialog(
      context: context,
      barrierDismissible: false, // 避免誤觸關閉
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isSubmitting = false;

          return StatefulBuilder(
            builder: (context, setInnerState) {
              return AlertDialog(
                title: Text(isReply ? '回覆留言' : '新增留言 (${_getCategoryName(provider.selectedCategory)})'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isReply)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(child: Text(avatar)),
                              const SizedBox(width: 8),
                              Text('以 $username 的身分發言'),
                            ],
                          ),
                        ),
                      TextField(
                        controller: contentController,
                        enabled: !isSubmitting, // 提交時鎖定輸入
                        decoration: InputDecoration(
                          labelText: isReply ? '回覆內容' : '留言內容',
                          hintText: isReply ? '輸入您的回覆...' : '輸入您的留言...',
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        minLines: 3,
                        textInputAction: TextInputAction.newline,
                        autofocus: true,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('取消')),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null // 提交中禁用按鈕
                        : () async {
                            final content = contentController.text.trim();
                            if (content.isNotEmpty) {
                              // 更新內部狀態顯示 Loading
                              setInnerState(() => isSubmitting = true);
                              try {
                                await provider.addMessage(
                                  user: username.isNotEmpty ? username : 'Anonymous',
                                  avatar: avatar,
                                  content: content,
                                  parentId: parentId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('留言傳送成功！'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setInnerState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('傳送失敗: $e'), backgroundColor: Colors.red));
                                }
                              }
                            }
                          },
                    child: const Text('發送'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showReplyDialog(
    BuildContext context,
    MessageProvider provider,
    String username,
    String avatar,
    String parentId,
  ) {
    _showAddMessageDialog(context, provider, username, avatar, parentId);
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'Important':
        return '重要公告';
      case 'Chat':
        return '討論區';
      case 'Gear':
        return '裝備協調';
      default:
        return category;
    }
  }
}

/// Tab 3: 裝備頁 (獨立頁籤)
class _GearTab extends StatelessWidget {
  const _GearTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GearProvider>(
      builder: (context, provider, child) {
        final mealProvider = Provider.of<MealProvider>(context);
        final totalWeight = provider.totalWeightKg + mealProvider.totalWeightKg;

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 官方建議裝備連結
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: const Text('官方建議裝備清單'),
                  subtitle: const Text('台灣山林悠遊網提供'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(ExternalLinks.gearPdfUrl),
                ),
              ),
              const SizedBox(height: 8),
              // 總重量
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('總重量 (含糧食)', style: TextStyle(fontSize: 18)),
                      Text(
                        '${totalWeight.toStringAsFixed(2)} kg',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 糧食計畫卡片
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.bento, color: Colors.orange, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('糧食計畫', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(
                                mealProvider.totalWeightKg > 0
                                    ? '已規劃 ${mealProvider.totalWeightKg.toStringAsFixed(2)} kg'
                                    : '尚未規劃',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 分類清單
              if (provider.allItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.backpack_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('目前沒有自定義裝備', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ...provider.itemsByCategory.entries.map(
                  (entry) => Card(
                    child: ExpansionTile(
                      maintainState: true,
                      initiallyExpanded: true,
                      leading: Icon(_getCategoryIcon(entry.key)),
                      title: Text('${_getCategoryName(entry.key)} (${entry.value.length}件)'),
                      subtitle: Text(
                        '${entry.value.fold<double>(0, (sum, item) => sum + item.weight).toStringAsFixed(0)}g',
                      ),
                      children: entry.value
                          .map(
                            (item) => ListTile(
                              leading: Checkbox(
                                value: item.isChecked,
                                onChanged: (_) => provider.toggleChecked(item.key),
                              ),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                  color: item.isChecked ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Text('${item.weight.toStringAsFixed(0)}g'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                // 裝備刪除不需確認 (依需求)
                                onPressed: () => provider.deleteItem(item.key),
                              ),
                              onTap: () => provider.toggleChecked(item.key),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 80), // 底部留白
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddGearDialog(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sleep':
        return Icons.bed;
      case 'Cook':
        return Icons.restaurant;
      case 'Wear':
        return Icons.checkroom;
      case 'Other':
        return Icons.category;
      default:
        return Icons.inventory_2;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'Sleep':
        return '睡眠系統';
      case 'Cook':
        return '炊具與飲食';
      case 'Wear':
        return '穿著';
      case 'Other':
        return '其他';
      default:
        return category;
    }
  }

  void _showAddGearDialog(BuildContext context, GearProvider provider) {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    String selectedCategory = 'Other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新增裝備'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '裝備名稱', hintText: '例如：睡袋'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: '重量 (公克)', hintText: '例如：1200'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: '分類'),
                items: const [
                  DropdownMenuItem(value: 'Sleep', child: Text('睡眠系統')),
                  DropdownMenuItem(value: 'Cook', child: Text('炊具與飲食')),
                  DropdownMenuItem(value: 'Wear', child: Text('穿著')),
                  DropdownMenuItem(value: 'Other', child: Text('其他')),
                ],
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final weight = double.tryParse(weightController.text) ?? 0;
                if (name.isNotEmpty && weight > 0) {
                  provider.addItem(name: name, weight: weight, category: selectedCategory);
                  ToastService.success('已新增：$name');
                  Navigator.pop(context);
                }
              },
              child: const Text('新增'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab 4: 資訊整合頁 (步道概況 + 工具 + 外部連結)
class _InfoTab extends StatefulWidget {
  const _InfoTab({super.key});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  bool _isElevationExpanded = false;
  bool _isTimeMapExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 頂部視覺圖 (嘉明湖)
        SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/jiaming_lake.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey),
              ),
              // 漸層遮罩
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 16,
                child: Text(
                  '嘉明湖國家步道',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 內容列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 步道概況
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('步道概況', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatItem(context, Icons.straighten, '全長', '13 km'),
                          _buildStatItem(
                            context,
                            Icons.landscape,
                            '海拔 (點擊展開高度圖)',
                            '2320~3603m',
                            onTap: () => setState(() => _isElevationExpanded = !_isElevationExpanded),
                            highlight: _isElevationExpanded,
                          ),
                          _buildStatItem(
                            context,
                            Icons.timer,
                            '路程時間',
                            '點擊查看參考圖',
                            onTap: () => setState(() => _isTimeMapExpanded = !_isTimeMapExpanded),
                            highlight: _isTimeMapExpanded,
                          ),
                        ],
                      ),

                      // 高度圖 (可縮合)
                      AnimatedCrossFade(
                        firstChild: const SizedBox(height: 0, width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📏 高度變化圖',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/images/elevation_profile.png', fit: BoxFit.contain),
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: _isElevationExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      // 路程時間圖 (可縮合)
                      AnimatedCrossFade(
                        firstChild: const SizedBox(height: 0, width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⏱️ 路程時間參考',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/images/trail_time_map.png', fit: BoxFit.contain),
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: _isTimeMapExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        '嘉明湖國家步道為中央山脈南二段的一部分，穿越台灣鐵杉林、高山深谷與箭竹草原，以高山寒原與藍寶石般的嘉明湖聞名。',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchUrl(ExternalLinks.permitUrl),
                              icon: const Icon(Icons.assignment_turned_in),
                              label: const Text('申請入山證'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchUrl(ExternalLinks.cwaUrl),
                              icon: const Icon(Icons.wb_sunny),
                              label: const Text('氣象預報'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewerScreen())),
                          icon: const Icon(Icons.map),
                          label: const Text('查看步道導覽地圖'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 外部資訊連結
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_work, color: Colors.brown),
                      title: const Text('山屋預約申請'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.cabinUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.public, color: Colors.indigo),
                      title: const Text('台灣山林悠遊網 (官網)'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.trailPageUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.map, color: Colors.green),
                      title: const Text('GPX 軌跡檔下載 (健行筆記)'),
                      trailing: const Icon(Icons.download, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.gpxUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud, color: Colors.blue),
                      title: const Text('Windy 天氣預報'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.windyUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                      title: const Text('中央氣象署 (三叉山)'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.cwaUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 電話訊號資訊
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.signal_cellular_alt),
                  title: const Text('電話訊號資訊', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: const [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SignalInfoRow(location: '起點 ~ 3.3K', signal: '有訊號'),
                          _SignalInfoRow(location: '3.3K ~ 向陽山屋', signal: '無訊號'),
                          _SignalInfoRow(location: '黑水塘稜線', signal: '中華/遠傳 1~2 格'),
                          _SignalInfoRow(location: '向陽山屋 ~ 10K', signal: '無訊號'),
                          _SignalInfoRow(location: '10K', signal: '遠傳微弱 (風大易失溫)'),
                          _SignalInfoRow(location: '10.5K', signal: '遠傳 2 格穩定'),
                          _SignalInfoRow(location: '嘉明湖本湖', signal: '中華/遠傳 (視雲況)'),
                          SizedBox(height: 8),
                          Text('💡 建議使用遠傳門號以獲得較多通訊點', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: highlight
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 20, color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highlight ? Theme.of(context).colorScheme.primary : null,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }
}

/// 訊號資訊行
class _SignalInfoRow extends StatelessWidget {
  final String location;
  final String signal;

  const _SignalInfoRow({required this.location, required this.signal});

  @override
  Widget build(BuildContext context) {
    final isNoSignal = signal.contains('無');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isNoSignal ? Icons.signal_cellular_off : Icons.signal_cellular_alt,
            size: 16,
            color: isNoSignal ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(location)),
          Text(
            signal,
            style: TextStyle(color: isNoSignal ? Colors.red : null, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
