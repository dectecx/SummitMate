import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/di.dart';
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

      // 強制深色主題
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SummitMate 山友'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ItineraryTab(),
          _CollaborationTab(),
          _ToolsTab(),
        ],
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
            icon: Icon(Icons.build),
            label: '工具',
          ),
        ],
      ),
    );
  }
}

/// Tab 1: 行程頁 (Placeholder - Phase 5 完整實作)
class _ItineraryTab extends StatelessWidget {
  const _ItineraryTab();

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
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isCheckedIn
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                      child: item.isCheckedIn
                          ? const Icon(Icons.check, color: Colors.white)
                          : Text('${index + 1}'),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      item.isCheckedIn
                          ? '實際: ${item.actualTime?.hour.toString().padLeft(2, '0')}:${item.actualTime?.minute.toString().padLeft(2, '0')}'
                          : '預計: ${item.estTime}',
                    ),
                    trailing: Text('${item.altitude}m'),
                    onTap: () => _showCheckInDialog(context, item, provider),
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('現在時間打卡'),
            onTap: () {
              provider.checkInNow(item.id);
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
                  item.id,
                  DateTime(now.year, now.month, now.day, time.hour, time.minute),
                );
              }
            },
          ),
          if (item.isCheckedIn)
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('清除打卡'),
              onTap: () {
                provider.clearCheckIn(item.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

/// Tab 2: 協作頁 (Placeholder)
class _CollaborationTab extends StatelessWidget {
  const _CollaborationTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // 分類切換 + 同步按鈕
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Gear', label: Text('🎒 裝備')),
                        ButtonSegment(value: 'Plan', label: Text('💡 建議')),
                        ButtonSegment(value: 'Misc', label: Text('💬 雜項')),
                      ],
                      selected: {provider.selectedCategory},
                      onSelectionChanged: (selected) {
                        provider.selectCategory(selected.first);
                      },
                    ),
                  ),
                  IconButton(
                    icon: provider.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    onPressed: provider.isSyncing ? null : () => provider.sync(),
                  ),
                ],
              ),
            ),
            // 留言列表
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.currentCategoryMessages.isEmpty
                      ? const Center(child: Text('尚無留言'))
                      : ListView.builder(
                          itemCount: provider.currentCategoryMessages.length,
                          itemBuilder: (context, index) {
                            final msg = provider.currentCategoryMessages[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(msg.content),
                                subtitle: Text('${msg.user} · ${msg.timestamp.month}/${msg.timestamp.day}'),
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
}

/// Tab 3: 工具頁 (Placeholder)
class _ToolsTab extends StatelessWidget {
  const _ToolsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GearProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 外部資訊區
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('外部資訊', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud),
                    title: const Text('開啟 Windy (向陽山屋)'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      // TODO: launchUrl
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.thermostat),
                    title: const Text('開啟 中央氣象署 (海端鄉)'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      // TODO: launchUrl
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 裝備區
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('我的裝備清單', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: 新增裝備 Dialog
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('新增'),
                        ),
                      ],
                    ),
                  ),
                  if (provider.allItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('尚無裝備，點擊右上角新增'),
                    )
                  else
                    ...provider.itemsByCategory.entries.map((entry) => ExpansionTile(
                      title: Text('${_getCategoryName(entry.key)} (${entry.value.length}件)'),
                      subtitle: Text('${entry.value.fold<double>(0, (sum, item) => sum + item.weight).toStringAsFixed(0)}g'),
                      children: entry.value.map((item) => CheckboxListTile(
                        value: item.isChecked,
                        onChanged: (_) => provider.toggleChecked(item.id!),
                        title: Text(item.name),
                        secondary: Text('${item.weight.toStringAsFixed(0)}g'),
                      )).toList(),
                    )),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '總重量: ${provider.totalWeightKg.toStringAsFixed(2)} kg',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
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
}
