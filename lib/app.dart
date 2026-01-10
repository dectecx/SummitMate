import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/di.dart';
import 'infrastructure/tools/toast_service.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/auth/auth_state.dart';
import 'presentation/providers/auth_provider.dart' hide AuthState;
import 'presentation/providers/gear_library_provider.dart';
import 'presentation/providers/gear_provider.dart';
import 'presentation/providers/itinerary_provider.dart';
import 'presentation/providers/map_provider.dart';
import 'presentation/providers/meal_provider.dart';
import 'presentation/providers/message_provider.dart';
import 'presentation/providers/poll_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/trip_provider.dart';
import 'presentation/screens/home_screen.dart';

/// SummitMate 主應用程式
class SummitMateApp extends StatelessWidget {
  const SummitMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit()..checkAuthStatus(),
      child: MultiProvider(
        providers: [
          // Auth Provider (優先載入)
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TripProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ItineraryProvider()),
          ChangeNotifierProvider(create: (_) => MessageProvider()),
          ChangeNotifierProvider(create: (_) => getIt<GearProvider>()),
          ChangeNotifierProvider(create: (_) => GearLibraryProvider()),
          ChangeNotifierProvider(create: (_) => MealProvider()),
          ChangeNotifierProvider(create: (_) => PollProvider()),
          ChangeNotifierProvider(create: (_) => MapProvider()),
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
