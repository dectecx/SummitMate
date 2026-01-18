import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../core/di.dart';
import '../../infrastructure/mock/mock_connectivity_service.dart';
import '../../infrastructure/mock/mock_poll_service.dart';
import '../../infrastructure/tools/tutorial_service.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/itinerary_tab.dart';
import '../widgets/gear_tab.dart';
import '../widgets/info_tab.dart';
import 'collaboration_tab.dart';
import '../../infrastructure/mock/mock_weather_service.dart';
import '../../infrastructure/mock/mock_geolocator_service.dart';
import '../../infrastructure/mock/mock_sync_service.dart';
import '../../domain/interfaces/i_weather_service.dart';
import '../../domain/interfaces/i_geolocator_service.dart';
import '../../domain/interfaces/i_sync_service.dart';

// Mock Repositories
import '../../data/repositories/mock/mock_itinerary_repository.dart';
import '../../data/repositories/mock/mock_message_repository.dart';
import '../../data/repositories/mock/mock_trip_repository.dart';
import '../../data/repositories/mock/mock_gear_repository.dart';
import '../../data/repositories/mock/mock_gear_library_repository.dart';
import '../../data/repositories/mock/mock_poll_repository.dart';
import '../../data/repositories/mock/mock_settings_repository.dart';

// Providers & Cubits
import '../cubits/trip/trip_cubit.dart';
import '../cubits/gear/gear_cubit.dart';
import '../cubits/gear_library/gear_library_cubit.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/message/message_cubit.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/settings/settings_cubit.dart';

/// 教學引導畫面
class TutorialScreen extends StatefulWidget {
  final TutorialTopic? topic;

  const TutorialScreen({super.key, this.topic});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentTab = 0;
  bool _isEditMode = false;
  OverlayEntry? _tutorialEntry;

  final _keyTabItinerary = GlobalKey();
  final _keyTabGear = GlobalKey();
  final _keyTabMessage = GlobalKey();
  final _keyTabInfo = GlobalKey();
  final _keyBtnEdit = GlobalKey();
  final _keyBtnUpload = GlobalKey();
  final _keyBtnSync = GlobalKey();
  final _keyTabPolls = GlobalKey();
  final _keyInfoElevation = GlobalKey();
  final _keyInfoTimeMap = GlobalKey();
  final _keyExpandedElevation = GlobalKey();
  final _keyExpandedTimeMap = GlobalKey();
  final GlobalKey<InfoTabState> _keyInfoTab = GlobalKey();

  late final MockItineraryRepository _mockItineraryRepo;
  late final MockTripRepository _mockTripRepo;

  // Mock Cubits/Providers
  late final TripCubit _mockTripCubit;
  late final ItineraryCubit _mockItineraryCubit;
  late final SyncCubit _mockSyncCubit;
  late final GearCubit _mockGearCubit;
  late final GearLibraryCubit _mockGearLibraryCubit;
  late final MessageCubit _mockMessageCubit;
  late final PollCubit _mockPollCubit;
  late final SettingsCubit _mockSettingsCubit;

  @override
  void initState() {
    super.initState();

    getIt.pushNewScope(scopeName: 'tutorial_scope');
    getIt.registerSingleton<IWeatherService>(MockWeatherService());
    getIt.registerSingleton<IGeolocatorService>(MockGeolocatorService());
    getIt.registerSingleton<ISyncService>(MockSyncService());

    _mockItineraryRepo = MockItineraryRepository();
    _mockTripRepo = MockTripRepository();

    // Init Cubits
    _mockTripCubit = TripCubit(tripRepository: _mockTripRepo, syncService: MockSyncService());
    _mockTripCubit.loadTrips();

    _mockItineraryCubit = ItineraryCubit(repository: _mockItineraryRepo, tripRepository: _mockTripRepo);

    _mockSyncCubit = SyncCubit(syncService: MockSyncService());

    _mockGearCubit = GearCubit(repository: MockGearRepository());

    _mockGearLibraryCubit = GearLibraryCubit(
      repository: MockGearLibraryRepository(),
      gearRepository: MockGearRepository(),
      tripRepository: _mockTripRepo,
    );

    _mockMessageCubit = MessageCubit(
      repository: MockMessageRepository(),
      tripRepository: _mockTripRepo,
      syncService: MockSyncService(),
    );

    _mockSettingsCubit = SettingsCubit(repository: MockSettingsRepository(), prefs: getIt<SharedPreferences>());

    _mockPollCubit = PollCubit(
      pollService: MockPollService(),
      pollRepository: MockPollRepository(),
      connectivity: MockConnectivityService(),
      prefs: getIt<SharedPreferences>(),
    );

    // Initial Data Setup
    Future.microtask(() async {
      await _mockTripCubit.loadTrips();
      await _mockTripCubit.setActiveTrip(MockItineraryRepository.mockTripId);

      await _mockItineraryCubit.loadItinerary();
      await _mockGearCubit.loadGear(MockItineraryRepository.mockTripId);
      await _mockGearLibraryCubit.loadItems();
      await _mockMessageCubit.loadMessages();
      await _mockPollCubit.loadPolls();
      await _mockSettingsCubit.loadSettings();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTutorial();
    });
  }

  @override
  void dispose() {
    getIt.popScope();
    _tutorialEntry?.remove();
    _mockTripCubit.close();
    _mockItineraryCubit.close();
    _mockSyncCubit.close();
    _mockGearCubit.close();
    _mockGearLibraryCubit.close();
    _mockMessageCubit.close();
    _mockPollCubit.close();
    _mockSettingsCubit.close();

    super.dispose();
  }

  void _startTutorial() {
    final topic = widget.topic ?? TutorialTopic.all;
    final isFullTutorial = topic == TutorialTopic.all;

    _tutorialEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        targets: TutorialService.initTargets(
          keyTabItinerary: _keyTabItinerary,
          keyTabMessage: _keyTabMessage,
          keyTabGear: _keyTabGear,
          keyTabInfo: _keyTabInfo,
          keyBtnEdit: _keyBtnEdit,
          keyBtnUpload: _keyBtnUpload,
          keyBtnSync: _keyBtnSync,
          keyTabPolls: _keyTabPolls,
          keyInfoElevation: _keyInfoElevation,
          keyInfoTimeMap: _keyInfoTimeMap,
          keyExpandedElevation: _keyExpandedElevation,
          keyExpandedTimeMap: _keyExpandedTimeMap,
          topic: topic,
          onSwitchToItinerary: () async {
            if (mounted) setState(() => _currentTab = 0);
            if (_isEditMode) setState(() => _isEditMode = false);
            await _waitForUI();
          },
          onFocusUpload: () async {
            setState(() {
              _currentTab = 0;
              _isEditMode = true;
            });
          },
          onFocusSync: () async {
            if (_isEditMode) setState(() => _isEditMode = false);
          },
          onSwitchToGear: () async {
            if (mounted) setState(() => _currentTab = 1);
            await _waitForUI();
          },
          onSwitchToMessage: () async {
            if (mounted) setState(() => _currentTab = 2);
            await _waitForUI();
          },
          onSwitchToInfo: () async {
            if (mounted) setState(() => _currentTab = 3);
            await _waitForUI();
          },
          onFocusElevation: () async {
            // 切換分頁並等待渲染
            if (mounted) setState(() => _currentTab = 3);
            await _waitForUI();
            
            // 展開高度圖
            _keyInfoTab.currentState?.expandElevation();
            
            // 等待動畫 (AnimatedCrossFade duration is 300ms)
            await Future.delayed(const Duration(milliseconds: 350));
          },
          onFocusTimeMap: () async {
            // 切換分頁並等待渲染
            if (mounted) setState(() => _currentTab = 3);
            await _waitForUI();

            // 展開時間圖
            _keyInfoTab.currentState?.expandTimeMap();
            
            // 等待動畫
            await Future.delayed(const Duration(milliseconds: 350));
          },
        ),
        onFinish: _finishTutorial,
        onSkip: _finishTutorial,
        showSkipTopic: isFullTutorial,
        onSkipTopic: isFullTutorial
            ? (nextIndex) {
                // 重建 overlay 並跳到指定索引
                _tutorialEntry?.remove();
                _startTutorialFromIndex(nextIndex);
              }
            : null,
      ),
    );

    Overlay.of(context).insert(_tutorialEntry!);
  }

  void _startTutorialFromIndex(int startIndex) {
    final topic = widget.topic ?? TutorialTopic.all;
    final isFullTutorial = topic == TutorialTopic.all;
    final targets = TutorialService.initTargets(
      keyTabItinerary: _keyTabItinerary,
      keyTabMessage: _keyTabMessage,
      keyTabGear: _keyTabGear,
      keyTabInfo: _keyTabInfo,
      keyBtnEdit: _keyBtnEdit,
      keyBtnUpload: _keyBtnUpload,
      keyBtnSync: _keyBtnSync,
      keyTabPolls: _keyTabPolls,
      keyInfoElevation: _keyInfoElevation,
      keyInfoTimeMap: _keyInfoTimeMap,
      keyExpandedElevation: _keyExpandedElevation,
      keyExpandedTimeMap: _keyExpandedTimeMap,
      topic: topic,
      onSwitchToItinerary: () async {
        if (mounted) setState(() => _currentTab = 0);
        await _waitForUI();
        if (_isEditMode) setState(() => _isEditMode = false);
      },
      onFocusUpload: () async {
        setState(() {
          _currentTab = 0;
          _isEditMode = true;
        });
      },
      onFocusSync: () async {
        if (_isEditMode) setState(() => _isEditMode = false);
      },
      onSwitchToGear: () async {
        if (mounted) setState(() => _currentTab = 1);
        await _waitForUI();
      },
      onSwitchToMessage: () async {
        if (mounted) setState(() => _currentTab = 2);
        await _waitForUI();
      },
      onSwitchToInfo: () async {
        if (mounted) setState(() => _currentTab = 3);
        await _waitForUI();
      },
      onFocusElevation: () async {
        // 切換分頁並等待渲染
        if (mounted) setState(() => _currentTab = 3);
        await _waitForUI();
        
        // 展開高度圖
        _keyInfoTab.currentState?.expandElevation();
        
        // 等待動畫
        await Future.delayed(const Duration(milliseconds: 350));
      },
      onFocusTimeMap: () async {
        // 切換分頁並等待渲染
        if (mounted) setState(() => _currentTab = 3);
        await _waitForUI();

        // 展開時間圖
        _keyInfoTab.currentState?.expandTimeMap();
        
        // 等待動畫
        await Future.delayed(const Duration(milliseconds: 350));
      },
    );

    // 從指定索引開始的子集
    final remainingTargets = targets.sublist(startIndex);

    _tutorialEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        targets: remainingTargets,
        onFinish: _finishTutorial,
        onSkip: _finishTutorial,
        showSkipTopic: isFullTutorial,
        onSkipTopic: isFullTutorial
            ? (nextIndex) {
                _tutorialEntry?.remove();
                // nextIndex 是相對於 remainingTargets 的索引，需要轉換
                _startTutorialFromIndex(startIndex + nextIndex);
              }
            : null,
      ),
    );

    Overlay.of(context).insert(_tutorialEntry!);
  }

  void _finishTutorial() {
    _tutorialEntry?.remove();
    _tutorialEntry = null;
    _mockSettingsCubit.completeOnboarding();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripCubit>.value(value: _mockTripCubit),
        BlocProvider<ItineraryCubit>.value(value: _mockItineraryCubit),
        BlocProvider<SyncCubit>.value(value: _mockSyncCubit),
        BlocProvider<GearCubit>.value(value: _mockGearCubit),
        BlocProvider<GearLibraryCubit>.value(value: _mockGearLibraryCubit),
        BlocProvider<MessageCubit>.value(value: _mockMessageCubit),
        BlocProvider<PollCubit>.value(value: _mockPollCubit),
        BlocProvider<SettingsCubit>.value(value: _mockSettingsCubit),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: Builder(
                builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () {}, tooltip: '選單'),
              ),
              title: const Text('SummitMate 山友'),
              actions: _buildAppBarActions(context),
            ),
            body: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _buildTabContent(_currentTab)),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentTab,
              onDestinationSelected: (_) {},
              destinations: [
                NavigationDestination(
                  key: _keyTabItinerary,
                  icon: const Icon(Icons.schedule),
                  selectedIcon: const Icon(Icons.schedule),
                  label: '行程',
                ),
                NavigationDestination(
                  key: _keyTabGear,
                  icon: const Icon(Icons.backpack_outlined),
                  selectedIcon: const Icon(Icons.backpack),
                  label: '裝備',
                ),
                NavigationDestination(
                  key: _keyTabMessage,
                  icon: const Icon(Icons.forum_outlined),
                  selectedIcon: const Icon(Icons.forum),
                  label: '互動',
                ),
                NavigationDestination(
                  key: _keyTabInfo,
                  icon: const Icon(Icons.info_outline),
                  selectedIcon: const Icon(Icons.info),
                  label: '資訊',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      if (_currentTab == 0) ...[
        IconButton(
          key: _keyBtnEdit,
          icon: Icon(_isEditMode ? Icons.check : Icons.edit),
          tooltip: _isEditMode ? '完成' : '編輯行程',
          onPressed: () => setState(() => _isEditMode = !_isEditMode),
        ),
        if (_isEditMode)
          IconButton(
            key: _keyBtnUpload,
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: '上傳至雲端',
            onPressed: () {},
          ),
        if (!_isEditMode) IconButton(icon: const Icon(Icons.map_outlined), tooltip: '查看地圖', onPressed: () {}),
      ],
      if (_currentTab == 2) IconButton(key: _keyBtnSync, icon: const Icon(Icons.sync), tooltip: '同步', onPressed: () {}),
      IconButton(icon: const Icon(Icons.settings), tooltip: '設定', onPressed: () {}),
    ];
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const ItineraryTab(key: ValueKey('tutorial_itinerary'));
      case 1:
        return GearTab(key: const ValueKey('tutorial_gear'), tripId: MockItineraryRepository.mockTripId);
      case 2:
        return const CollaborationTab(key: ValueKey('tutorial_collab'));
      case 3:
        return InfoTab(key: _keyInfoTab, expandedElevationKey: _keyExpandedElevation, expandedTimeMapKey: _keyExpandedTimeMap);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 等待 UI 渲染完成
  Future<void> _waitForUI() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }
}
