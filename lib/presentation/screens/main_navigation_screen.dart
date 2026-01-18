import 'package:flutter/material.dart';

import '../../infrastructure/tools/tutorial_service.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../../core/di.dart';
import '../cubits/message/message_cubit.dart';
import '../cubits/message/message_state.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/poll/poll_state.dart';
import '../../core/constants/role_constants.dart';
import '../../infrastructure/tools/usage_tracking_service.dart';

import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../../core/error/result.dart';

import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
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

import '../widgets/settings_dialog.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/itinerary_item.dart';

import 'collaboration_tab.dart';
import 'trip_list_screen.dart';
import 'map/map_screen.dart';

import '../widgets/ads/banner_ad_widget.dart';
import '../utils/tutorial_keys.dart';

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
      if (!mounted) return;
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
          _usageTrackingService!.start(currentUsername, userId: profile.id);

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

      // Reload Trips on mount (ensures correct data after re-login)
      if (context.mounted) {
        context.read<TripCubit>().loadTrips();
      }
    });
  }

  @override
  void dispose() {
    _usageTrackingService?.dispose();
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => SettingsDialog(onRestartTutorial: (topic) => _showTutorial(context, topic)),
    );
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
              await TutorialService.start(topic: TutorialTopic.all);
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
                              key: TutorialKeys.mainDrawerMenu,
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
                              if (activeTrip != null) ...[
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    // Determine Role
                                    final authState = context.read<AuthCubit>().state;
                                    final userId = (authState is AuthAuthenticated) ? authState.userId : '';
                                    final isOwner = activeTrip.userId == userId;
                                    final roleLabel = isOwner
                                        ? RoleConstants.displayName[RoleConstants.leader] ?? 'Leader'
                                        : RoleConstants.displayName[RoleConstants.member] ?? 'Member';
                                    final color = isOwner ? Colors.orange : Colors.blueGrey;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color, // Solid color for better contrast
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                      ),
                                      child: Text(
                                        roleLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                              key: TutorialKeys.mainSettings,
                              icon: const Icon(Icons.settings),
                              onPressed: () => _showSettingsDialog(context),
                              tooltip: '設定',
                            ),
                          ],
                        ),
                        drawer: const AppDrawer(), // 使用獨立的 AppDrawer Widget
                        body: Column(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: _buildTabContent(_currentIndex),
                              ),
                            ),
                            const BannerAdWidget(location: 'navigation_bottom'),
                          ],
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
                            NavigationDestination(
                              key: TutorialKeys.tabItinerary,
                              icon: const Icon(Icons.schedule),
                              selectedIcon: const Icon(Icons.schedule),
                              label: '行程',
                            ),
                            NavigationDestination(
                              key: TutorialKeys.tabGear,
                              icon: const Icon(Icons.backpack_outlined),
                              selectedIcon: const Icon(Icons.backpack),
                              label: '裝備',
                            ),
                            NavigationDestination(
                              key: TutorialKeys.tabMessage,
                              icon: const Icon(Icons.forum_outlined),
                              selectedIcon: const Icon(Icons.forum),
                              label: '互動',
                            ),
                            NavigationDestination(
                              key: TutorialKeys.tabInfo,
                              icon: const Icon(Icons.info_outline),
                              selectedIcon: const Icon(Icons.info),
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
  ///
  /// 流程：
  /// 1. 呼叫 [TripCubit.getCloudTrips] 取得雲端列表
  /// 2. 顯示列表供用戶選擇
  /// 3. 選定後呼叫 [_importAndSwitchTrip] 進行匯入
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

    if (result is Failure) {
      ToastService.error((result as Failure).exception.toString());
      return;
    }

    final cloudTrips = (result as Success<List<Trip>, Exception>).value;
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

  /// 匯入並切換行程
  ///
  /// 此過程包含：
  /// 1. 將 [Trip] 資料存入本地 (若存在則更新，不存在則新增)
  /// 2. 設定為當前活動行程 (Active Trip)
  /// 3. 呼叫 [SyncCubit.syncAll] 下載該行程的完整資料 (行程表、留言)
  ///
  /// [cloudTrip] 欲匯入的雲端行程物件
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
      final existing = await tripCubit.getTripById(cloudTrip.id);
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

  /// 顯示新增行程項目對話框
  /// 預設使用目前選擇的天數 (Selected Day)
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
        id: const Uuid().v4(),
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

  void _showTutorial(BuildContext context, TutorialTopic topic) {
    TutorialService.start(
      topic: topic,
      // 1. Navigation Tabs
      onSwitchToItinerary: () async {
        setState(() => _currentIndex = 0);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onSwitchToGear: () async {
        setState(() => _currentIndex = 1);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onSwitchToMessage: () async {
        setState(() => _currentIndex = 2);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onSwitchToInfo: () async {
        setState(() => _currentIndex = 3);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      // 2. Drawer / Settings
      onFocusDrawer: () async {
        Scaffold.of(context).openDrawer();
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusSettings: () async {
        // Warning: App Bar actions are hard to trigger programmatically without key access or rebuilding?
        // But the tutorial just points to them. The USER clicks them.
        // Wait, onFocus is PREPARATION.
        // If the drawer is needed, we open it.
        // If settings is needed, we usually don't need to do anything if it's on AppBar.
        await Future.delayed(const Duration(milliseconds: 300));
      },
      // 3. Actions that might need context or state
      onFocusUpload: () async {
        // Ensure we are on Itinerary Tab
        if (_currentIndex != 0) setState(() => _currentIndex = 0);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusSync: () async {
         // Ensure on Message Tab? Or just wait.
         if (_currentIndex != 2) setState(() => _currentIndex = 2); // Message Tab usually has Sync
         await Future.delayed(const Duration(milliseconds: 300));
      },
      // 4. Member Management Flow (Complex)
      onFocusManageTrips: () async {
        // Open Drawer to show "Manage Trips" item
        Scaffold.of(context).openDrawer();
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusTripListMember: () async {
        // This usually requires navigating to TripListScreen via Drawer Item click.
        // We can simulate it?
        Navigator.pop(context); // Close Drawer
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripListScreen()));
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusMemberFab: () async {
         // Requires being on MemberManagementScreen.
         // This is hard because TripListScreen -> MemberManagementScreen requires Trip ID.
         // We might need to skip this automation or just point to it.
         // PASS-THROUGH allows user to click.
         // IMPORTANT: TutorialService uses onFocus to PREPARE.
         // If we rely on User Action, we might not need to do anything here except wait.
         await Future.delayed(const Duration(milliseconds: 300));
      },
    );
  }
}
