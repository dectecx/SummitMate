import 'package:material_ui/material_ui.dart';

/// Deep teal taken from the app icon (lake and sky) on cool neutrals. Material 3, light and dark,
/// large touch targets (the app is used one-handed, outdoors), rounded shapes, flat cards.
abstract final class AppTheme {
  static const _seed = Color(0xFF0B7A99);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final text = Typography.material2021(platform: TargetPlatform.iOS).black.apply(fontFamilyFallback: const ['PingFang TC', 'Noto Sans TC']);
    RoundedRectangleBorder round(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        scrolledUnderElevation: 2,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: round(14), textStyle: const TextStyle(fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: round(14), side: BorderSide(color: scheme.outline))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: round(12))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(shape: round(16)),
      chipTheme: ChipThemeData(shape: round(10), side: BorderSide(color: scheme.outlineVariant)),
      segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(shape: round(12))),
      listTileTheme: ListTileThemeData(shape: round(12)),
      dialogTheme: DialogThemeData(shape: round(24), surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: round(12)),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
