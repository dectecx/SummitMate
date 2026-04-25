import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme.dart';
import 'core/di/injection.dart';
import 'infrastructure/tools/toast_service.dart';
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
import 'presentation/cubits/settings/settings_state.dart';
import 'presentation/cubits/group_event/group_event_cubit.dart';
import 'presentation/cubits/favorites/mountain/mountain_favorites_cubit.dart';
import 'presentation/cubits/favorites/group_event/group_event_favorites_cubit.dart';
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
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (_) => getIt<SyncCubit>()),
        BlocProvider(create: (_) => getIt<TripCubit>()..loadTrips()),
        BlocProvider(create: (_) => getIt<ItineraryCubit>()..loadItinerary()),
        BlocProvider(create: (_) => getIt<GearCubit>()),
        BlocProvider(create: (_) => getIt<GearLibraryCubit>()..loadItems()),
        BlocProvider(create: (_) => getIt<MessageCubit>()..loadMessages()),
        BlocProvider(create: (_) => getIt<PollCubit>()..loadPolls()),
        BlocProvider(create: (_) => getIt<MealCubit>()),
        BlocProvider(create: (_) => getIt<MapCubit>()..initLocation()),
        BlocProvider(create: (_) => getIt<OfflineMapCubit>()),
        BlocProvider(create: (_) => getIt<GroupEventCubit>()),
        BlocProvider(create: (_) => getIt<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => getIt<MountainFavoritesCubit>()..loadFavorites()),
        BlocProvider(create: (_) => getIt<GroupEventFavoritesCubit>()..loadFavorites()),
      ],
      child: _buildMaterialApp(),
    );
  }

  Widget _buildMaterialApp() {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) {
        if (previous is SettingsLoaded && current is SettingsLoaded) {
          return previous.settings.theme != current.settings.theme;
        }
        return true;
      },
      builder: (context, state) {
        // Default to Morandi if not loaded
        AppThemeType currentTheme = AppThemeType.nature;
        if (state is SettingsLoaded) {
          currentTheme = state.settings.theme;
        }

        return MaterialApp(
          title: 'SummitMate',
          debugShowCheckedModeBanner: false,
          navigatorObservers: const [],

          // Toast 訊息的 key
          scaffoldMessengerKey: ToastService.messengerKey,

          // 動態主題配色
          theme: AppTheme.getThemeData(currentTheme),
          themeMode: ThemeMode.light, // 目前強制 Light Mode，由 Strategy 控制顏色
          // 錯誤監聽與 Overlay
          builder: (context, child) {
            final content = GlobalTutorialWrapper(child: GlobalErrorListener(child: child ?? const SizedBox.shrink()));

            if (kIsWeb) {
              return content;
            }
            return content;
          },

          // 初始頁面
          home: const HomeScreen(),
        );
      },
    );
  }
}
