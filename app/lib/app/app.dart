import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
import '../core/settings/app_settings.dart';
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
      routerConfig: _router,
    );
  }
}
