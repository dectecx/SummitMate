import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
import '../core/settings/app_settings.dart';
import '../dev/dev_config.dart';
import '../dev/dev_tools_overlay.dart';
import '../shared/animations.dart';
import '../shared/brand/splash_overlay.dart';
import 'router.dart';
import 'theme.dart';

/// Stored theme choice: `system` (default), `light` or `dark`.
final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  return ref.watch(settingsStoreProvider).watch(SettingsStore.themeMode).map(
    (v) => switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
  );
});

class SummitMateApp extends ConsumerStatefulWidget {
  const SummitMateApp({super.key, required this.initialLocation});
  final String initialLocation;

  @override
  ConsumerState<SummitMateApp> createState() => _SummitMateAppState();
}

class _SummitMateAppState extends ConsumerState<SummitMateApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '山友 SummitMate',
      debugShowCheckedModeBanner: false,
      // The app is written in Traditional Chinese only, so the built-in parts (date and time pickers, the licence
      // page, tooltips) use it too, whatever language the phone is set to.
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) {
        var app = child ?? const SizedBox.shrink();
        if (ref.watch(devToolsVisibleProvider)) app = DevToolsOverlay(navigatorKey: _router.routerDelegate.navigatorKey, child: app);
        return SplashOverlay(enabled: ref.watch(splashEnabledProvider), animate: ref.watch(animationsSettingProvider).value ?? true, child: app);
      },
    );
  }
}
