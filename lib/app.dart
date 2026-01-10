import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/di.dart';
import 'infrastructure/tools/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/interfaces/i_settings_repository.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/auth/auth_state.dart';
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
import 'presentation/providers/auth_provider.dart' hide AuthState;
// import 'presentation/providers/map_provider.dart'; // Removed
// import 'presentation/providers/meal_provider.dart'; // Removed
import 'presentation/screens/home_screen.dart';

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
        BlocProvider(create: (_) => OfflineMapCubit()), // Register MealCubit
        BlocProvider(
          create: (context) =>
              SettingsCubit(repository: getIt<ISettingsRepository>(), prefs: getIt<SharedPreferences>())
                ..loadSettings(),
        ), // Register SettingsCubit
      ],
      child: MultiProvider(
        providers: [
          // Auth Provider (優先載入)
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // 當 Cubit 登入成功，同步通知 AuthProvider 更新狀態 (讓依賴 Provider 的組件正常運作)
              // validateSession 會重新從 AuthService 讀取最新的 UserProfile
              context.read<AuthProvider>().validateSession();
            } else if (state is AuthUnauthenticated) {
              // 當 Cubit 登出，同步通知 AuthProvider 清除狀態
              context.read<AuthProvider>().logout();
            }
          },
          child: _buildMaterialApp(),
        ),
      ),
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
      home: const HomeScreen(),
    );
  }
}
