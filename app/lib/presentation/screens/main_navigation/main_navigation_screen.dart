import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../core/di/injection.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

import '../../../domain/entities/itinerary_item.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../domain/repositories/i_auth_session_repository.dart';

import '../../cubits/message/message_cubit.dart';
import '../../cubits/message/message_state.dart';
import '../../cubits/poll/poll_cubit.dart';
import '../../cubits/poll/poll_state.dart';
import '../../cubits/trip/trip_cubit.dart';
import '../../cubits/trip/trip_state.dart';
import '../../cubits/sync/sync_cubit.dart';
import '../../cubits/sync/sync_state.dart';
import '../../cubits/itinerary/itinerary_cubit.dart';
import '../../cubits/itinerary/itinerary_state.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';

import '../map/map_screen.dart';

import '../../widgets/info_tab.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_drawer_content.dart';
import '../../widgets/itinerary_tab.dart';
import '../../widgets/gear_tab.dart';
import '../../widgets/itinerary_edit_dialog.dart';
import '../../widgets/settings_dialog.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/responsive_layout.dart';

import '../collaboration_tab.dart';

import 'widgets/main_app_bar.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'dialogs/trip_selection_dialog.dart';
import 'dialogs/welcome_dialog.dart';
import 'utils/cloud_upload_helper.dart';
import 'utils/tutorial_helper.dart';

/// App 的主要導航結構 (BottomNavigationBar + Drawer)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  UsageTrackingService? _usageTrackingService;

  @override
  void initState() {
    super.initState();
    // 連接同步回調
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsCubit = context.read<SettingsCubit>();

      // 初次啟動顯示歡迎畫面
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
      _usageTrackingService = getIt<UsageTrackingService>();
      getIt<IAuthSessionRepository>().getUserProfile().then((profile) {
        if (context.mounted && profile != null) {
          _usageTrackingService!.start(currentUsername, userId: profile.id);

          bool needUpdate = false;
          if (profile.displayName.isNotEmpty && currentUsername != profile.displayName) {
            needUpdate = true;
          }
          if (profile.avatar.isNotEmpty && currentAvatar != profile.avatar) {
            needUpdate = true;
          }

          if (needUpdate) {
            settingsCubit.updateProfile(profile.displayName, profile.avatar);
          }
        }
      });

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
    WelcomeDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncSuccess) {
              context.read<ItineraryCubit>().loadItinerary();
              context.read<MessageCubit>().loadMessages();
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
                      final bool isTripLoading = tripState is TripLoading;
                      final bool hasTrips = tripState is TripLoaded && tripState.trips.isNotEmpty;
                      final Trip? activeTrip = tripState is TripLoaded ? tripState.activeTrip : null;

                      final bool isMessageSyncing = messageState is MessageLoaded && messageState.isSyncing;
                      final bool isPollSyncing = pollState is PollLoaded && pollState.isSyncing;
                      final isLoading = isMessageSyncing || isPollSyncing || isTripLoading;

                      final settingsState = context.watch<SettingsCubit>().state;
                      final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
                      final bool isEditMode = itineraryState is ItineraryLoaded ? itineraryState.isEditMode : false;

                      if (!hasTrips && !isTripLoading) {
                        return Scaffold(
                          key: _scaffoldKey,
                          appBar: AppBar(
                            leading: IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              tooltip: '選單',
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
                          drawer: const AppDrawer(),
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
                                  onPressed: () => TripSelectionDialog.show(context),
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

                      return Scaffold(
                        key: _scaffoldKey,
                        drawer: ResponsiveLayout.isDesktop(context) ? null : const AppDrawer(),
                        drawerEnableOpenDragGesture: !ResponsiveLayout.isDesktop(context),
                        appBar: MainAppBar(
                          activeTrip: activeTrip,
                          isOffline: isOffline,
                          isLoading: isLoading,
                          currentIndex: _currentIndex,
                          isEditMode: isEditMode,
                          showLeading: !ResponsiveLayout.isDesktop(context),
                          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          onEditToggle: () => context.read<ItineraryCubit>().toggleEditMode(),
                          onUpload: () => CloudUploadHelper.handleCloudUpload(context),
                          onMap: () => _handleMapNavigation(context),
                          onSettings: () => _showSettingsDialog(context),
                        ),
                        body: ResponsiveLayout(
                          mobile: Column(
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
                          desktop: Row(
                            children: [
                              AppDrawerContent(
                                isSidebar: true,
                                currentIndex: _currentIndex,
                                onTabSelected: (index) {
                                  setState(() => _currentIndex = index);
                                  if (isEditMode) {
                                    context.read<ItineraryCubit>().toggleEditMode();
                                  }
                                },
                              ),
                              const VerticalDivider(thickness: 1, width: 1),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(child: _buildTabContent(_currentIndex)),
                                    const BannerAdWidget(location: 'navigation_bottom'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          tablet: Row(
                            children: [
                              NavigationRail(
                                selectedIndex: _currentIndex,
                                onDestinationSelected: (index) {
                                  setState(() => _currentIndex = index);
                                  if (isEditMode) {
                                    context.read<ItineraryCubit>().toggleEditMode();
                                  }
                                },
                                labelType: NavigationRailLabelType.all,
                                leading: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    IconButton(
                                      icon: const Icon(Icons.menu),
                                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                      tooltip: '選單',
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                                destinations: const [
                                  NavigationRailDestination(
                                    icon: Icon(Icons.hiking),
                                    selectedIcon: Icon(Icons.hiking),
                                    label: Text('行程'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.backpack_outlined),
                                    selectedIcon: Icon(Icons.backpack),
                                    label: Text('裝備'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.groups_outlined),
                                    selectedIcon: Icon(Icons.groups),
                                    label: Text('揪團/訊息'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.info_outline),
                                    selectedIcon: Icon(Icons.info),
                                    label: Text('資訊'),
                                  ),
                                ],
                              ),
                              const VerticalDivider(thickness: 1, width: 1),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(child: _buildTabContent(_currentIndex)),
                                    const BannerAdWidget(location: 'navigation_bottom'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        bottomNavigationBar: ResponsiveLayout(
                          mobile: MainBottomNavigationBar(
                            currentIndex: _currentIndex,
                            onDestinationSelected: (index) {
                              setState(() => _currentIndex = index);
                              if (isEditMode) {
                                context.read<ItineraryCubit>().toggleEditMode();
                              }
                            },
                          ),
                          desktop: const SizedBox.shrink(),
                        ),
                        floatingActionButton: (_currentIndex == 0 && isEditMode)
                            ? FloatingActionButton(
                                onPressed: () => _showAddItineraryDialog(context),
                                child: const Icon(Icons.add),
                              )
                            : null,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

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

  void _showTutorial(BuildContext context, TutorialTopic topic) {
    MainNavigationTutorialHelper.showTutorial(
      context: context,
      topic: topic,
      onTabSwitch: (index) => setState(() => _currentIndex = index),
      scaffoldKey: _scaffoldKey,
    );
  }

  void _handleMapNavigation(BuildContext context) {
    if (kIsWeb) {
      _showWebMapOptions(context);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
    }
  }

  void _showWebMapOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.map_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('網頁版地圖提示'),
          ],
        ),
        content: const Text(
          '目前網頁版尚未支援內建地圖與 GPX 檢視功能。\n\n'
          '建議您下載 Android / iOS App 獲得完整地圖體驗，\n'
          '或是在 Google Maps 中查看位置。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              const url = 'https://www.google.com/maps/search/?api=1&query=23.29,121.03';
              await url_launcher.launchUrl(Uri.parse(url));
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('在 Google Maps 開啟'),
          ),
        ],
      ),
    );
  }
}
