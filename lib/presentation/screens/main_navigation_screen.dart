import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/services.dart'; // for SystemNavigator
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/di.dart';
import '../../infrastructure/tools/log_service.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../cubits/message/message_cubit.dart';
import '../cubits/message/message_state.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/poll/poll_state.dart';
import '../../infrastructure/tools/usage_tracking_service.dart';
import '../../infrastructure/tools/hive_service.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';

import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
// import '../providers/message_provider.dart';
// import '../providers/poll_provider.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/itinerary/itinerary_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/app_drawer.dart';
import '../widgets/itinerary_tab.dart';
import '../widgets/gear_tab.dart';
import '../widgets/info_tab.dart';
import '../widgets/itinerary_edit_dialog.dart';
import '../widgets/tutorial_overlay.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/itinerary_item.dart';

import 'collaboration_tab.dart'; // Ensure this file exists, otherwise adapt
import 'map/map_screen.dart';
import 'tutorial_screen.dart';

/// App 的主要導航結構 (BottomNavigationBar + Drawer)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  UsageTrackingService? _usageTrackingService;

  @override
  void initState() {
    super.initState();
    // 連接同步回調
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsCubit = context.read<SettingsCubit>();

      // 初次啟動顯示歡迎畫面 (選擇是否進入教學)
      // Check state safely
      final state = settingsCubit.state;
      bool hasSeenOnboarding = false;
      String currentUsername = '';
      String currentAvatar = '';

      if (state is SettingsLoaded) {
        hasSeenOnboarding = state.hasSeenOnboarding;
        currentUsername = state.username;
        currentAvatar = state.avatar;
      }

      if (!hasSeenOnboarding) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _showWelcomeDialog(context);
        });
      }

      // 啟動使用狀態追蹤 (Web only)
      _usageTrackingService = UsageTrackingService();
      // Async fetch user profile
      getIt<IAuthSessionRepository>().getUserProfile().then((profile) {
        if (context.mounted && profile != null) {
          _usageTrackingService!.start(currentUsername, userId: profile.uuid);

          // Sync SettingsCubit if valid profile found on launch
          // This ensures AppDrawer shows correct info if local settings verify from cloud session
          bool needUpdate = false;
          if (profile.displayName.isNotEmpty && currentUsername != profile.displayName) {
            needUpdate = true;
          }
          if (profile.avatar.isNotEmpty && currentAvatar != profile.avatar) {
            needUpdate = true;
          }

          if (needUpdate) {
            // If local settings differ from cloud session, update local
            // Assuming session is truth (or at least we want to sync them)
            settingsCubit.updateProfile(profile.displayName, profile.avatar);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _usageTrackingService?.dispose();
    super.dispose();
  }

  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('歡迎來到 SummitMate'),
        content: const Text('為了讓您快速上手，我們準備了簡易的教學引導。\n您想要現在觀看嗎？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 略過教學：標記完成
              context.read<SettingsCubit>().completeOnboarding();
            },
            child: const Text('直接開始 (略過)'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // 進入教學 -> 結束後顯示匯入行程
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen()));
              if (context.mounted) {
                // 教學結束後，自動跳出匯入選單
                _showTripSelectionDialog(context);
              }
            },
            child: const Text('教學引導'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 SyncCubit 狀態以更新 UI 與重載資料
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncSuccess) {
              // 同步成功，重載資料
              context.read<ItineraryCubit>().loadItinerary();
              context.read<MessageCubit>().loadMessages();
              // context.read<PollCubit>().fetchPolls(); // Optional: trigger poll sync if needed
              context.read<SettingsCubit>().updateLastSyncTime(state.timestamp);
              ToastService.success(state.message);
            } else if (state is SyncFailure) {
              ToastService.error(state.errorMessage);
            }
          },
        ),
        BlocListener<TripCubit, TripState>(
          listener: (context, state) {
            if (state is TripLoaded) {
              // 當行程切換或載入完成，重載 Itinerary
              context.read<ItineraryCubit>().loadItinerary();
            }
          },
        ),
      ],
      child: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, itineraryState) {
          return BlocBuilder<MessageCubit, MessageState>(
            builder: (context, messageState) {
              return BlocBuilder<PollCubit, PollState>(
                builder: (context, pollState) {
                  return BlocBuilder<TripCubit, TripState>(
                    builder: (context, tripState) {
                      // final tripProvider = context.watch<TripProvider>(); // Removed

                      final bool isTripLoading = tripState is TripLoading;
                      final bool hasTrips = tripState is TripLoaded && tripState.trips.isNotEmpty;
                      final Trip? activeTrip = tripState is TripLoaded ? tripState.activeTrip : null;

                      final bool isMessageSyncing = messageState is MessageLoaded && messageState.isSyncing;
                      final bool isPollSyncing = pollState is PollLoaded && pollState.isSyncing;

                      final isLoading = isMessageSyncing || isPollSyncing || isTripLoading;

                      // Use SettingsCubit for offline mode
                      final settingsState = context.watch<SettingsCubit>().state;
                      final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

                      // Extract Itinerary State
                      final bool isEditMode = itineraryState is ItineraryLoaded ? itineraryState.isEditMode : false;

                      // 如果沒有行程，顯示空狀態 (Import / Create)
                      if (!hasTrips && !isTripLoading) {
                        return Scaffold(
                          appBar: AppBar(
                            leading: Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                                tooltip: '選單',
                              ),
                            ),
                            title: const Text('SummitMate 山友'),
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                tooltip: '歡迎訊息 / 教學',
                                onPressed: () => _showWelcomeDialog(context),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () => _showSettingsDialog(context),
                                tooltip: '設定',
                              ),
                            ],
                          ),
                          drawer: const AppDrawer(), // 允許在空狀態使用側邊欄
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hiking, size: 80, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  '歡迎使用 SummitMate',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text('您目前還沒有任何行程', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                  onPressed: () => _showTripSelectionDialog(context),
                                  icon: const Icon(Icons.cloud_download),
                                  label: const Text('從雲端匯入行程'),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => context.read<TripCubit>().createDefaultTrip(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('建立新行程'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final scaffold = Scaffold(
                        appBar: AppBar(
                          leading: Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                              tooltip: '選單',
                            ),
                          ),
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(activeTrip?.name ?? 'SummitMate 山友', overflow: TextOverflow.ellipsis),
                              ),
                              if (isOffline) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud_off, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('離線', style: TextStyle(fontSize: 11, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          bottom: isLoading
                              ? const PreferredSize(
                                  preferredSize: Size.fromHeight(4.0),
                                  child: LinearProgressIndicator(),
                                )
                              : null,
                          actions: [
                            // Tab 0: 行程編輯與地圖 (僅在有行程時顯示)
                            if (_currentIndex == 0) ...[
                              IconButton(
                                icon: Icon(isEditMode ? Icons.check : Icons.edit),
                                tooltip: isEditMode ? '完成' : '編輯行程',
                                onPressed: () => context.read<ItineraryCubit>().toggleEditMode(),
                              ),
                              if (isEditMode)
                                IconButton(
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  tooltip: '上傳至雲端',
                                  onPressed: () => _handleCloudUpload(context),
                                ),
                              if (!isEditMode) ...[
                                IconButton(
                                  icon: const Icon(Icons.map_outlined),
                                  tooltip: '查看地圖',
                                  onPressed: () =>
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                                ),
                              ],
                            ],
                            // 設定按鈕
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () => _showSettingsDialog(context),
                              tooltip: '設定',
                            ),
                          ],
                        ),
                        drawer: const AppDrawer(), // 使用獨立的 AppDrawer Widget
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
                            if (isEditMode) {
                              context.read<ItineraryCubit>().toggleEditMode();
                            }
                          },
                          destinations: [
                            const NavigationDestination(
                              icon: Icon(Icons.schedule),
                              selectedIcon: Icon(Icons.schedule),
                              label: '行程',
                            ),
                            const NavigationDestination(
                              icon: Icon(Icons.backpack_outlined),
                              selectedIcon: Icon(Icons.backpack),
                              label: '裝備',
                            ),
                            const NavigationDestination(
                              icon: Icon(Icons.forum_outlined),
                              selectedIcon: Icon(Icons.forum),
                              label: '互動',
                            ),
                            const NavigationDestination(
                              icon: Icon(Icons.info_outline),
                              selectedIcon: Icon(Icons.info),
                              label: '資訊',
                            ),
                          ],
                        ),
                        floatingActionButton: (_currentIndex == 0 && isEditMode)
                            ? FloatingActionButton(
                                onPressed: () => _showAddItineraryDialog(context),
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
            },
          ); // Message
        },
      ), // Itinerary
    );
  }

  /// 顯示行程選擇對話框 (從雲端匯入)
  Future<void> _showTripSelectionDialog(BuildContext context) async {
    final tripCubit = context.read<TripCubit>();

    // 1. 顯示 Loading 並取得 Trip List
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final result = await tripCubit.getCloudTrips();
    if (!context.mounted) return;
    Navigator.pop(context); // Close Loading

    if (!result.isSuccess) {
      ToastService.error(result.errorMessage ?? '無法取得雲端行程列表');
      return;
    }

    final cloudTrips = result.trips;
    if (cloudTrips.isEmpty) {
      ToastService.info('雲端目前沒有行程資料');
      return;
    }

    // 2. 顯示選擇列表
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('選擇要匯入的行程'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cloudTrips.length,
            itemBuilder: (itemContext, index) {
              final trip = cloudTrips[index];
              return ListTile(
                leading: const Icon(Icons.map),
                title: Text(trip.name),
                subtitle: Text(trip.startDate.toIso8601String().split('T').first),
                onTap: () {
                  Navigator.pop(dialogContext);
                  // 使用最外層穩定的 context
                  _importAndSwitchTrip(context, trip);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消'))],
      ),
    );
  }

  Future<void> _importAndSwitchTrip(BuildContext context, Trip cloudTrip) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tripCubit = context.read<TripCubit>();

      // 1. 新增/更新 Trip Meta 到本地
      // 先檢查本地是否已有此 ID
      final existing = tripCubit.getTripById(cloudTrip.id);
      if (existing != null) {
        await tripCubit.updateTrip(cloudTrip);
      } else {
        await tripCubit.importTrip(cloudTrip);
      }

      // 2. 切換為 Active
      await tripCubit.setActiveTrip(cloudTrip.id);

      // 3. 觸發 Sync (下載該 Trip 的 itinerary/messages)
      // 使用 SyncCubit 統一執行同步
      if (!context.mounted) return;
      await context.read<SyncCubit>().syncAll(force: true);

      if (context.mounted) {
        Navigator.pop(context); // Close Loading
      }
      ToastService.success('行程匯入成功');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ToastService.error('匯入失敗: $e');
    }
  }

  /// 建立對應頁籤內容 (帶 key 以支援 AnimatedSwitcher)
  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const ItineraryTab(key: ValueKey(0));
      case 1:
        final tripId = context.read<TripCubit>().state is TripLoaded
            ? (context.read<TripCubit>().state as TripLoaded).activeTrip?.id ?? ''
            : '';
        return GearTab(key: const ValueKey(1), tripId: tripId);
      case 2:
        return const CollaborationTab(key: ValueKey(2));
      case 3:
        return const InfoTab(key: ValueKey(3));
      default:
        return const ItineraryTab(key: ValueKey(0));
    }
  }

  void _showAddItineraryDialog(BuildContext context) async {
    final itineraryCubit = context.read<ItineraryCubit>();
    String selectedDay = 'D1';
    final state = itineraryCubit.state;
    if (state is ItineraryLoaded) {
      selectedDay = state.selectedDay;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ItineraryEditDialog(defaultDay: selectedDay),
    );

    if (result != null) {
      if (!context.mounted) return;
      final tripState = context.read<TripCubit>().state;
      String tripId = '';
      if (tripState is TripLoaded && tripState.activeTrip != null) {
        tripId = tripState.activeTrip!.id;
      }

      final item = ItineraryItem(
        uuid: const Uuid().v4(), // Correct property name is uuid, not id
        tripId: tripId,
        day: selectedDay,
        name: result['name'] ?? '',
        estTime: result['estTime'] ?? '',
        altitude: result['altitude'] ?? 0,
        distance: result['distance'] ?? 0.0,
        note: result['note'] ?? '',
      );
      itineraryCubit.addItem(item);
    }
  }

  void _showClearDataDialog(BuildContext context) {
    // 預設選項狀態
    bool clearItinerary = true;
    bool clearMessages = true;
    bool clearGear = true;
    bool clearGearLibrary = true;
    bool clearWeather = true;
    bool clearSettings = false;
    bool clearLogs = false;
    bool clearPolls = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) => AlertDialog(
          title: const Text('⚠️ 清除本地資料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('選擇要清除的資料類型：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('行程資料'),
                  subtitle: const Text('包含所有行程與內容', style: TextStyle(fontSize: 11)),
                  value: clearItinerary,
                  onChanged: (v) => setState(() => clearItinerary = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('留言資料'),
                  value: clearMessages,
                  onChanged: (v) => setState(() => clearMessages = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('裝備清單'),
                  subtitle: const Text('公開/標準裝備組合', style: TextStyle(fontSize: 11)),
                  value: clearGear,
                  onChanged: (v) => setState(() => clearGear = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('個人裝備庫'),
                  value: clearGearLibrary,
                  onChanged: (v) => setState(() => clearGearLibrary = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('天氣快取'),
                  value: clearWeather,
                  onChanged: (v) => setState(() => clearWeather = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('設定與身分'),
                  subtitle: const Text('清除後需重新設定暱稱', style: TextStyle(fontSize: 11)),
                  value: clearSettings,
                  onChanged: (v) => setState(() => clearSettings = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('App 日誌'),
                  value: clearLogs,
                  onChanged: (v) => setState(() => clearLogs = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('投票資料'),
                  value: clearPolls,
                  onChanged: (v) => setState(() => clearPolls = v ?? false),
                ),
                const Divider(),
                const Text(
                  '此操作無法復原！',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // 執行選擇性清除
                await getIt<HiveService>().clearSelectedData(
                  clearTrips: clearItinerary,
                  clearItinerary: clearItinerary,
                  clearMessages: clearMessages,
                  clearGear: clearGear,
                  clearGearLibrary: clearGearLibrary,
                  clearWeather: clearWeather,
                  clearSettings: clearSettings,
                  clearLogs: clearLogs,
                  clearPolls: clearPolls,
                );

                // 顯示重啟提示對話框 (不可取消)
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => AlertDialog(
                      title: const Text('✅ 清除完成'),
                      content: Text(kIsWeb ? '資料已清除，請重新載入網頁以完成操作。' : '資料已清除，請重新啟動 App 以完成操作。'),
                      actions: [
                        FilledButton(
                          onPressed: () {
                            if (kIsWeb) {
                              // Web: Reload the page
                              launchUrl(Uri.base, webOnlyWindowName: '_self');
                            } else {
                              // Mobile: Close the app
                              SystemNavigator.pop();
                            }
                          },
                          child: Text(kIsWeb ? '重新載入' : '關閉 App'),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('確定清除'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) async {
    final settingsCubit = context.read<SettingsCubit>();
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    // Get current state values safely
    String currentUsername = '';
    String currentAvatar = '🐻';
    DateTime? lastSyncTime;

    final state = settingsCubit.state;
    if (state is SettingsLoaded) {
      currentUsername = state.username;
      currentAvatar = state.avatar;
      lastSyncTime = state.lastSyncTime;
    }

    final controller = TextEditingController(text: currentUsername);

    // Avatar 選擇邏輯
    final List<String> avatarOptions = ['🐻', '🦊', '🐼', '🐨', '🦁', '🐸', '🐢', '🐙'];
    String selectedAvatar = currentAvatar;

    PackageInfo? packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          final versionStr = packageInfo != null ? 'v${packageInfo.version}' : '';

          String lastSyncStr = '尚未同步';
          if (lastSyncTime != null) {
            lastSyncStr =
                '${lastSyncTime.month}/${lastSyncTime.day} ${lastSyncTime.hour}:${lastSyncTime.minute.toString().padLeft(2, '0')}';
          }

          return BlocBuilder<SettingsCubit, SettingsState>(
            bloc: settingsCubit,
            builder: (context, state) {
              bool isOfflineMode = false;
              if (state is SettingsLoaded) {
                isOfflineMode = state.isOfflineMode;
              }

              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('設定'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(versionStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('同步: $lastSyncStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 320),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ====== 暱稱與頭像區塊 ======
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (ctx) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: avatarOptions.map((icon) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() => selectedAvatar = icon);
                                          Navigator.pop(ctx);
                                        },
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: selectedAvatar == icon
                                              ? Theme.of(context).colorScheme.primaryContainer
                                              : Colors.grey.shade100,
                                          child: Text(icon, style: const TextStyle(fontSize: 24)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(dialogContext).colorScheme.primaryContainer,
                                  radius: 36,
                                  child: Text(selectedAvatar, style: const TextStyle(fontSize: 32)),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(dialogContext).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: '暱稱',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
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
                              final newName = controller.text.trim();
                              if (newName.isNotEmpty) {
                                // 1. 同步到雲端 (如果已登入)
                                if (authState is AuthAuthenticated && !authState.isOffline && !authState.isGuest) {
                                  try {
                                    final result = await authCubit.updateProfile(
                                      displayName: newName,
                                      avatar: selectedAvatar,
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

                                // 2. 更新本地設定
                                settingsCubit.updateProfile(newName, selectedAvatar);

                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            child: const Text('儲存設定'),
                          ),
                        ),
                        const Divider(height: 32),

                        // ====== 離線模式 ======
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
                              await settingsCubit.toggleOfflineMode();
                            },
                          ),
                        ),
                        const Divider(height: 32),

                        // ====== 重看教學引導 ======
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('重看教學引導'),
                          onTap: () async {
                            if (innerContext.mounted) {
                              Navigator.pop(innerContext);
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (context.mounted) {
                                  _showTutorial(context);
                                }
                              });
                            }
                          },
                        ),
                        const Divider(height: 32),

                        // ====== 開發資訊 (縮合區塊) ======
                        ExpansionTile(
                          leading: const Icon(Icons.developer_mode),
                          title: const Text('開發資訊'),
                          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                              title: const Text('清除本地資料庫', style: TextStyle(color: Colors.red)),
                              subtitle: const Text('選擇要刪除的資料類型', style: TextStyle(fontSize: 11)),
                              onTap: () async {
                                Navigator.pop(dialogContext);
                                _showClearDataDialog(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.article_outlined, size: 20),
                              title: const Text('查看日誌'),
                              onTap: () {
                                Navigator.pop(dialogContext);
                                _showLogViewer(context);
                              },
                            ),
                            const ListTile(
                              leading: Icon(Icons.code, size: 20),
                              title: Text('開發者資訊'),
                              subtitle: Text('by 哲', style: TextStyle(fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('關閉'))],
              );
            },
          );
        },
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (p0, p1, st) => TutorialOverlay(
          targets: const [], // TODO: Restore original targets if possible
          onFinish: () => Navigator.pop(context),
          onSkip: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _handleCloudUpload(BuildContext context) async {
    // 檢查離線模式
    final state = context.read<SettingsCubit>().state;
    final settingsIsOffline = state is SettingsLoaded && state.isOfflineMode;
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

    // 2. 檢查衝突 (Use SyncCubit)
    final hasConflict = await context.read<SyncCubit>().checkItineraryConflict();

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
                context.read<SyncCubit>().uploadItinerary(); // 執行上傳
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
                context.read<SyncCubit>().uploadItinerary();
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
                          final (isSuccess, message) = await LogService.uploadToCloud();
                          if (isSuccess) {
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
                          if (context.mounted) Navigator.pop(context);
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
