import 'package:material_ui/material_ui.dart';

/// Forest green on warm neutrals. Material 3, light and dark, large touch targets
/// (the app is used one-handed, outdoors).
abstract final class AppTheme {
  static const _seed = Color(0xFF2E6B3F);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52))),
      navigationBarTheme: const NavigationBarThemeData(height: 68),
    );
  }
}
