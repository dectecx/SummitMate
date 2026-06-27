import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../core/di/injection.dart';
import '../../../domain/enums/app_view.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/domain/domain.dart';

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
import '../../cubits/tutorial/tutorial_cubit.dart';
import '../../cubits/tutorial/tutorial_state.dart';
import '../../cubits/gear/gear_cubit.dart';
import '../../cubits/meal/meal_cubit.dart';

import '../map/map_screen.dart';
import '../collaboration_tab.dart';

import '../../widgets/info_tab.dart';
import '../../widgets/itinerary_tab.dart';
import '../../widgets/gear_tab.dart';
import '../../widgets/itinerary_edit_dialog.dart';
import '../../widgets/settings_dialog.dart';
import '../../widgets/tutorial/tutorial_aware_builder.dart';

import 'widgets/main_tab_scaffold.dart';
import 'widgets/empty_trip_scaffold.dart';
import 'dialogs/welcome_dialog.dart';
import 'utils/cloud_upload_helper.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsCubit = context.read<SettingsCubit>();

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
        _updateTrackingView(_currentIndex);
      }
    });
  }

  void _updateTrackingView(int index) {
    if (_usageTrackingService == null) return;
    AppView view = AppView.unknown;
    switch (index) {
      case 0:
        view = AppView.itinerary;
        break;
      case 1:
        view = AppView.gear;
        break;
      case 2:
        view = AppView.collaboration;
        break;
      case 3:
        view = AppView.info;
        break;
    }
    _usageTrackingService!.updateView(view);
  }

  @override
  void dispose() {
    _usageTrackingService?.dispose();
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (dialogContext) => const SettingsDialog());
  }

  void _showWelcomeDialog(BuildContext context) {
    WelcomeDialog.show(context);
  }

  void _handleTabChanged(BuildContext context, int index, bool isEditMode) {
    setState(() {
      _currentIndex = index;
      _updateTrackingView(index);
    });
    if (isEditMode) {
      context.read<ItineraryCubit>().toggleEditMode();
    }
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
              final activeTripId = state.activeTrip?.id;
              if (activeTripId != null) {
                context.read<GearCubit>().loadGear(activeTripId);
                context.read<MealCubit>().loadMealPlans(activeTripId);
              } else {
                context.read<GearCubit>().reset();
                context.read<MealCubit>().reset();
              }
            }
          },
        ),
        BlocListener<TutorialCubit, TutorialState>(
          listener: (context, state) {
            if (state is TutorialActive) {
              int targetIndex = _resolveTutorialTabIndex(state);
              if (targetIndex != -1 && targetIndex != _currentIndex) {
                setState(() {
                  _currentIndex = targetIndex;
                  _updateTrackingView(targetIndex);
                });
              }
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
                  return TutorialAwareTripBuilder(
                    builder: (context, activeTrip, trips) {
                      return BlocBuilder<SyncCubit, SyncState>(
                        builder: (context, syncState) {
                          final bool isTripLoading = context.watch<TripCubit>().state is TripLoading;
                          final bool isMessageSyncing = messageState is MessageLoaded && messageState.isSyncing;
                          final bool isPollSyncing = pollState is PollLoaded && pollState.isSyncing;
                          final bool isSyncInProgress = syncState is SyncInProgress;
                          final bool isLoading = isMessageSyncing || isPollSyncing || isTripLoading || isSyncInProgress;
                          final bool isEditMode = itineraryState is ItineraryLoaded ? itineraryState.isEditMode : false;

                          if (trips.isEmpty && !isTripLoading) {
                            return EmptyTripScaffold(
                              scaffoldKey: _scaffoldKey,
                              onWelcomePressed: () => _showWelcomeDialog(context),
                              onSettingsPressed: () => _showSettingsDialog(context),
                            );
                          }

                          return MainTabScaffold(
                            scaffoldKey: _scaffoldKey,
                            activeTrip: activeTrip,
                            isLoading: isLoading,
                            currentIndex: _currentIndex,
                            isEditMode: isEditMode,
                            onTabChanged: (index) => _handleTabChanged(context, index, isEditMode),
                            onEditToggle: () => context.read<ItineraryCubit>().toggleEditMode(),
                            onUpload: () => CloudUploadHelper.handleCloudUpload(context),
                            onMap: () => _handleMapNavigation(context),
                            onSettings: () => _showSettingsDialog(context),
                            onAddItinerary: () => _showAddItineraryDialog(context),
                            buildTabContent: _buildTabContent,
                          );
                        },
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

  int _resolveTutorialTabIndex(TutorialActive state) {
    switch (state.chapterId) {
      case 'itinerary':
        return 0;
      case 'gear':
        return 1;
      case 'collaboration':
      case 'groupEvent':
        return 2;
      case 'cloud':
        return 0;
      case 'quick_tour':
        if (state.currentStepIndex == 0) return 0;
        if (state.currentStepIndex == 1) return 1;
        if (state.currentStepIndex == 2) return 1;
        if (state.currentStepIndex == 3) return 0;
        return -1;
      default:
        return -1;
    }
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
        id: const Uuid().v7(),
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
