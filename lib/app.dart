import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/di.dart';
import 'services/toast_service.dart';
import 'presentation/providers/auth_provider.dart';
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
    return MultiProvider(
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

      // 初始頁面
      home: const HomeScreen(),
    );
  }
}
