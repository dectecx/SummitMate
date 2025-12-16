import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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

/// Onboarding 畫面 (設定暱稱)
class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen();

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() => _isSubmitting = true);
    
    await context.read<SettingsProvider>().updateUsername(username);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.terrain,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '歡迎使用 SummitMate',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '為了方便隊友辨識，請輸入你的暱稱：',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '你的暱稱',
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SummitMate 山友'),
            actions: [
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
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _buildTabContent(_currentIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: '行程',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum),
                label: '協作',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.backpack),
                label: '裝備',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                label: '資訊',
              ),
            ],
          ),
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
        return const _ToolsTab(key: ValueKey(3));
      default:
        return const _ItineraryTab(key: ValueKey(0));
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settingsProvider.username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '暱稱',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '上次同步: ${settingsProvider.lastSyncTimeFormatted ?? "尚未同步"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showLogViewer(context);
              },
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('查看日誌'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                settingsProvider.setUsername(newName);
              }
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
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
                          await LogService.clearAll();
                          Navigator.pop(context);
                          ToastService.info('日誌已清除');
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('清除'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
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
                        backgroundColor: item.isCheckedIn
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
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
                            style: TextStyle(
                              color: item.isCheckedIn ? Colors.green : null,
                            ),
                          ),
                          Text(
                            '海拔 ${item.altitude}m  |  累計 ${cumulativeDistance.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: item.note.isNotEmpty 
                          ? const Icon(Icons.info_outline, size: 20)
                          : null,
                      onTap: () => _showCheckInDialog(context, item, provider),
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

  void _showCheckInDialog(
    BuildContext context,
    dynamic item,
    ItineraryProvider provider,
  ) {
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
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
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
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  final now = DateTime.now();
                  provider.checkIn(
                    item.key,
                    DateTime(now.year, now.month, now.day, time.hour, time.minute),
                  );
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
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
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
                          ButtonSegment(value: 'Gear', label: Text('裝備')),
                          ButtonSegment(value: 'Plan', label: Text('建議')),
                          ButtonSegment(value: 'Misc', label: Text('雜項')),
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
                                  title: Text(msg.content),
                                  subtitle: Text('${msg.user} · ${msg.timestamp.month}/${msg.timestamp.day}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (replies.isNotEmpty)
                                        Text('${replies.length}', style: Theme.of(context).textTheme.bodySmall),
                                      IconButton(
                                        icon: const Icon(Icons.reply, size: 20),
                                        onPressed: () => _showReplyDialog(
                                          context, messageProvider, settingsProvider.username, msg.uuid),
                                        tooltip: '回覆',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        onPressed: () => _confirmDelete(context, messageProvider, msg.uuid),
                                        tooltip: '刪除',
                                      ),
                                    ],
                                  ),
                                  children: replies.map((reply) => ListTile(
                                    leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
                                    title: Text(reply.content),
                                    subtitle: Text('${reply.user} · ${reply.timestamp.month}/${reply.timestamp.day}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () => _confirmDelete(context, messageProvider, reply.uuid),
                                    ),
                                  )).toList(),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMessageDialog(context, messageProvider, settingsProvider.username, null),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
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

  void _showAddMessageDialog(BuildContext context, MessageProvider provider, String username, String? parentId) {
    final contentController = TextEditingController();
    final isReply = parentId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReply ? '回覆留言' : '新增留言 (${_getCategoryName(provider.selectedCategory)})'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: contentController,
            decoration: InputDecoration(
              labelText: isReply ? '回覆內容' : '留言內容',
              hintText: isReply ? '輸入您的回覆...' : '輸入您的留言...',
              border: const OutlineInputBorder(),
            ),
            maxLines: 5,  // 加大輸入框
            minLines: 3,
            textInputAction: TextInputAction.newline, // 允許換行
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final content = contentController.text.trim();
              if (content.isNotEmpty) {
                provider.addMessage(
                  user: username.isNotEmpty ? username : 'Anonymous',
                  content: content,
                  parentId: parentId,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('發送'),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, MessageProvider provider, String username, String parentId) {
    _showAddMessageDialog(context, provider, username, parentId);
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'Gear': return '裝備';
      case 'Plan': return '建議';
      case 'Misc': return '雜項';
      default: return category;
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
        return Scaffold(
          body: provider.allItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.backpack_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('尚無裝備', style: TextStyle(fontSize: 18)),
                      Text('點擊右下角新增裝備', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 總重量
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('總重量', style: TextStyle(fontSize: 18)),
                            Text(
                              '${provider.totalWeightKg.toStringAsFixed(2)} kg',
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
                    // 分類清單
                    ...provider.itemsByCategory.entries.map((entry) => Card(
                      child: ExpansionTile(
                        leading: Icon(_getCategoryIcon(entry.key)),
                        title: Text('${_getCategoryName(entry.key)} (${entry.value.length}件)'),
                        subtitle: Text('${entry.value.fold<double>(0, (sum, item) => sum + item.weight).toStringAsFixed(0)}g'),
                        children: entry.value.map((item) => CheckboxListTile(
                          value: item.isChecked,
                          onChanged: (_) => provider.toggleChecked(item.key),
                          title: Text(item.name),
                          secondary: Text('${item.weight.toStringAsFixed(0)}g'),
                        )).toList(),
                      ),
                    )),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sleep': return Icons.bed;
      case 'Cook': return Icons.restaurant;
      case 'Wear': return Icons.checkroom;
      case 'Other': return Icons.category;
      default: return Icons.inventory_2;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'Sleep': return '睡眠系統';
      case 'Cook': return '炊具與飲食';
      case 'Wear': return '穿著';
      case 'Other': return '其他';
      default: return category;
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
                decoration: const InputDecoration(
                  labelText: '裝備名稱',
                  hintText: '例如：睡袋',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: '重量 (公克)',
                  hintText: '例如：1200',
                ),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final weight = double.tryParse(weightController.text) ?? 0;
                if (name.isNotEmpty && weight > 0) {
                  provider.addItem(
                    name: name,
                    weight: weight,
                    category: selectedCategory,
                  );
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

/// Tab 4: 資訊頁 (外部連結與訊號資訊)
class _ToolsTab extends StatelessWidget {
  const _ToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 外部資訊區 (可摺疊)
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.language),
            title: const Text('外部資訊', style: TextStyle(fontWeight: FontWeight.bold)),
            initiallyExpanded: true,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud),
                title: const Text('開啟 Windy (嘉明湖)'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchUrl(ExternalLinks.windyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.thermostat),
                title: const Text('開啟 中央氣象署 (三叉山)'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchUrl(ExternalLinks.cwaUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 電話訊號資訊 (可摺疊)
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.signal_cellular_alt),
            title: const Text('電話訊號資訊', style: TextStyle(fontWeight: FontWeight.bold)),
            initiallyExpanded: true,
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
                    Text(
                      '💡 建議使用遠傳門號以獲得較多通訊點',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
            style: TextStyle(
              color: isNoSignal ? Colors.red : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
