import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'core/di.dart';
import 'infrastructure/tools/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/interfaces/i_settings_repository.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/sync/sync_cubit.dart';
import 'presentation/cubits/trip/trip_cubit.dart';
import 'presentation/cubits/gear/gear_cubit.dart';
import 'presentation/cubits/gear_library/gear_library_cubit.dart';
import 'presentation/cubits/itinerary/itinerary_cubit.dart';
import 'presentation/cubits/message/message_cubit.dart';
import 'presentation/cubits/poll/poll_cubit.dart';
import 'presentation/cubits/meal/meal_cubit.dart';
import 'presentation/cubits/map/map_cubit.dart';
import 'presentation/cubits/map/offline_map_cubit.dart';
import 'presentation/cubits/settings/settings_cubit.dart';
import 'presentation/cubits/group_event/group_event_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/widgets/global_error_listener.dart';
import 'presentation/widgets/global_tutorial_wrapper.dart';

/// SummitMate 主應用程式
class SummitMateApp extends StatelessWidget {
  const SummitMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()..checkAuthStatus()),
        BlocProvider(create: (context) => SyncCubit()),
        BlocProvider(create: (context) => TripCubit()..loadTrips()),
        BlocProvider(create: (context) => ItineraryCubit()..loadItinerary()),
        BlocProvider(create: (context) => GearCubit()),
        BlocProvider(create: (context) => GearLibraryCubit()..loadItems()),
        BlocProvider(create: (context) => MessageCubit()..loadMessages()),
        BlocProvider(create: (context) => PollCubit()..loadPolls()),
        BlocProvider(create: (_) => MealCubit()),
        BlocProvider(create: (_) => MapCubit()..initLocation()),
        BlocProvider(create: (_) => OfflineMapCubit()),
        BlocProvider(create: (_) => GroupEventCubit()),
        BlocProvider(
          create: (context) =>
              SettingsCubit(repository: getIt<ISettingsRepository>(), prefs: getIt<SharedPreferences>())
                ..loadSettings(),
        ),
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

      // 錯誤監聽與 Overlay
      builder: (context, child) {
        return GlobalTutorialWrapper(
          child: GlobalErrorListener(child: child ?? const SizedBox.shrink()),
        );
      },

      // 初始頁面
      home: const HomeScreen(),
    );
  }
}
