import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di.dart';
import '../../services/tutorial_service.dart';
import '../../services/poll_service.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/itinerary_tab.dart';
import '../widgets/gear_tab.dart';
import '../widgets/info_tab.dart';
import 'collaboration_tab.dart';
import '../../services/sync_service.dart';
import '../../services/mock/mock_weather_service.dart';
import '../../services/mock/mock_geolocator_service.dart';
import '../../services/mock/mock_sync_service.dart';
import '../../services/google_sheets_service.dart';
import '../../services/interfaces/i_weather_service.dart';
import '../../services/interfaces/i_geolocator_service.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../data/repositories/interfaces/i_message_repository.dart';
import '../../data/repositories/interfaces/i_settings_repository.dart';

// Mock Repositories
import '../../data/repositories/mock/mock_itinerary_repository.dart';
import '../../data/repositories/mock/mock_message_repository.dart';
import '../../data/repositories/mock/mock_trip_repository.dart';
import '../../data/repositories/mock/mock_gear_repository.dart';
import '../../data/repositories/mock/mock_gear_library_repository.dart';
import '../../data/repositories/mock/mock_poll_repository.dart';
import '../../data/repositories/mock/mock_settings_repository.dart';

// Providers
import '../providers/itinerary_provider.dart';
import '../providers/message_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/gear_provider.dart';
import '../providers/gear_library_provider.dart';
import '../providers/poll_provider.dart';
import '../providers/settings_provider.dart';

/// 教學引導畫面
///
/// 使用 Mock Repository 注入的 Provider，復用真實 Widget，
/// 確保教學畫面與主程式 UI 一致，且不會觸發任何真實 API。
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  /// 當前顯示的頁籤索引
  int _currentTab = 0;

  /// 是否處於編輯模式（用於行程頁籤）
  bool _isEditMode = false;

  /// Tutorial Overlay Entry
  OverlayEntry? _tutorialEntry;

  // GlobalKeys 供教學 Overlay 定位目標元素
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
  final GlobalKey<InfoTabState> _keyInfoTab = GlobalKey();

  // Mock Repositories
  late final MockItineraryRepository _mockItineraryRepo;
  late final MockMessageRepository _mockMessageRepo;
  late final MockTripRepository _mockTripRepo;
  late final MockGearRepository _mockGearRepo;
  late final MockGearLibraryRepository _mockGearLibraryRepo;
  late final MockPollRepository _mockPollRepo;
  late final MockSettingsRepository _mockSettingsRepo;

  // Mock Providers (使用 Mock Repository 初始化)
  late final ItineraryProvider _mockItineraryProvider;
  late final MessageProvider _mockMessageProvider;
  late final TripProvider _mockTripProvider;
  late final GearProvider _mockGearProvider;
  late final GearLibraryProvider _mockGearLibraryProvider;
  late final PollProvider _mockPollProvider;
  late final SettingsProvider _mockSettingsProvider;

  @override
  void initState() {
    super.initState();

    // 1. Push a new scope to override services
    getIt.pushNewScope(scopeName: 'tutorial_scope');

    // 2. Register Mock Services
    getIt.registerSingleton<IWeatherService>(MockWeatherService());
    getIt.registerSingleton<IGeolocatorService>(MockGeolocatorService());
    getIt.registerSingleton<SyncService>(
      MockSyncService(
        sheetsService: getIt<GoogleSheetsService>(),
        tripRepo: getIt<ITripRepository>(),
        itineraryRepo: getIt<IItineraryRepository>(),
        messageRepo: getIt<IMessageRepository>(),
        settingsRepo: getIt<ISettingsRepository>(),
      ),
    );

    // 3. Setup Providers with Mocks
    _mockItineraryRepo = MockItineraryRepository();
    _mockMessageRepo = MockMessageRepository();
    _mockTripRepo = MockTripRepository();
    _mockGearRepo = MockGearRepository();
    _mockGearLibraryRepo = MockGearLibraryRepository();
    _mockPollRepo = MockPollRepository();
    _mockSettingsRepo = MockSettingsRepository();

    _mockTripProvider = TripProvider(repository: _mockTripRepo);
    _mockItineraryProvider = ItineraryProvider(repository: _mockItineraryRepo, tripRepository: _mockTripRepo);
    _mockMessageProvider = MessageProvider(repository: _mockMessageRepo, tripRepository: _mockTripRepo);
    _mockGearProvider = GearProvider(repository: _mockGearRepo);
    _mockGearLibraryProvider = GearLibraryProvider(
      repository: _mockGearLibraryRepo,
      gearRepository: _mockGearRepo,
      tripRepository: _mockTripRepo,
    );
    _mockPollProvider = PollProvider(
      pollRepository: _mockPollRepo,
      settingsRepo: _mockSettingsRepo,
      prefs: getIt<SharedPreferences>(),
      pollService: getIt<PollService>(),
    );
    _mockSettingsProvider = SettingsProvider(repository: _mockSettingsRepo);
    _mockGearProvider.setTripId(MockItineraryRepository.mockTripId);

    // 4. Start Tutorial after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTutorial();
    });
  }

  @override
  void dispose() {
    // Pop the scope to restore real services
    getIt.popScope();

    _tutorialEntry?.remove();
    // Dispose mock providers
    _mockTripProvider.dispose();
    _mockItineraryProvider.dispose();
    _mockMessageProvider.dispose();
    _mockGearProvider.dispose();
    _mockGearLibraryProvider.dispose();
    _mockPollProvider.dispose();
    _mockSettingsProvider.dispose();
    super.dispose();
  }

  /// 啟動教學導覽
  void _startTutorial() {
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
          onSwitchToItinerary: () async {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _currentTab = 0);
            });
            if (_isEditMode) {
              setState(() => _isEditMode = false);
            }
          },
          onFocusUpload: () async {
            setState(() {
              _currentTab = 0;
              _isEditMode = true;
            });
          },
          onFocusSync: () async {
            if (_isEditMode) {
              setState(() => _isEditMode = false);
            }
          },
          onSwitchToGear: () async {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _currentTab = 1);
            });
          },
          onSwitchToMessage: () async {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _currentTab = 2);
            });
          },
          onSwitchToInfo: () async {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _currentTab = 3);
            });
          },
          onFocusElevation: () async {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _currentTab = 3);
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              _keyInfoTab.currentState?.expandElevation();
            });
          },
          onFocusTimeMap: () async {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _currentTab = 3);
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              _keyInfoTab.currentState?.expandTimeMap();
            });
          },
        ),
        onFinish: _finishTutorial,
        onSkip: _finishTutorial,
      ),
    );

    Overlay.of(context).insert(_tutorialEntry!);
  }

  /// 結束教學導覽
  void _finishTutorial() {
    _tutorialEntry?.remove();
    _tutorialEntry = null;

    // 標記教學完成並返回主畫面
    context.read<SettingsProvider>().completeOnboarding();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 使用 MultiProvider 覆蓋全域 Provider，注入 Mock 版本
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _mockTripProvider),
        ChangeNotifierProvider.value(value: _mockItineraryProvider),
        ChangeNotifierProvider.value(value: _mockMessageProvider),
        ChangeNotifierProvider.value(value: _mockGearProvider),
        ChangeNotifierProvider.value(value: _mockGearLibraryProvider),
        ChangeNotifierProvider.value(value: _mockPollProvider),
        ChangeNotifierProvider.value(value: _mockSettingsProvider),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {}, // 教學模式：不執行動作
                  tooltip: '選單',
                ),
              ),
              title: const Text('SummitMate 山友'),
              actions: _buildAppBarActions(context),
            ),
            body: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _buildTabContent(_currentTab)),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentTab,
              onDestinationSelected: (_) {}, // 教學模式：禁止手動切換
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

  /// 建立 AppBar 動作按鈕
  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // 行程頁籤的編輯/上傳按鈕
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
            onPressed: () {}, // 教學模式：不執行
          ),
        if (!_isEditMode)
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '查看地圖',
            onPressed: () {}, // 教學模式：不執行
          ),
      ],
      // 互動頁籤的同步按鈕
      if (_currentTab == 2)
        IconButton(
          key: _keyBtnSync,
          icon: const Icon(Icons.sync),
          tooltip: '同步',
          onPressed: () {}, // 教學模式：不執行
        ),
      // 設定按鈕
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: '設定',
        onPressed: () {}, // 教學模式：不執行
      ),
    ];
  }

  /// 建立頁籤內容（復用真實 Widget）
  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const ItineraryTab(key: ValueKey('tutorial_itinerary'));
      case 1:
        return GearTab(key: const ValueKey('tutorial_gear'), tripId: MockItineraryRepository.mockTripId);
      case 2:
        return const CollaborationTab(key: ValueKey('tutorial_collab'));
      case 3:
        return InfoTab(key: _keyInfoTab);
      default:
        return const SizedBox.shrink();
    }
  }
}
