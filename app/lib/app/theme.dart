import 'package:material_ui/material_ui.dart';

/// Pine teal from the app icon on warm paper neutrals, with one clay accent and moss for quiet highlights.
/// Few colours on purpose: surfaces and text carry the screen, colour only marks what matters.
/// Material 3, light and dark, large touch targets (used one-handed, outdoors), rounded shapes, flat cards.
abstract final class AppTheme {
  static const _seed = Color(0xFF1F6F7A);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final scheme = brightness == Brightness.light
        ? base.copyWith(
            primary: const Color(0xFF1F6F7A),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFD3E8EA),
            onPrimaryContainer: const Color(0xFF0C3A41),
            secondaryContainer: const Color(0xFFDFE8D6), // moss
            onSecondaryContainer: const Color(0xFF2A3826),
            tertiary: const Color(0xFFA8672E), // clay
            tertiaryContainer: const Color(0xFFF4E4D0),
            onTertiaryContainer: const Color(0xFF4A2A0C),
            surface: const Color(0xFFF7F4EC), // paper
            surfaceContainerLowest: const Color(0xFFFFFCF6),
            surfaceContainerLow: const Color(0xFFFBF8F0),
            surfaceContainer: const Color(0xFFF1EDE3),
            surfaceContainerHigh: const Color(0xFFEAE5D9),
            surfaceContainerHighest: const Color(0xFFE4DECF),
            onSurface: const Color(0xFF1E2321),
            onSurfaceVariant: const Color(0xFF4F5853),
            outline: const Color(0xFF8A9189),
            outlineVariant: const Color(0xFFDDD6C6),
          )
        : base.copyWith(
            primary: const Color(0xFF8CCBD2),
            onPrimary: const Color(0xFF0A3238),
            primaryContainer: const Color(0xFF214E56),
            onPrimaryContainer: const Color(0xFFD3E8EA),
            secondaryContainer: const Color(0xFF334030),
            onSecondaryContainer: const Color(0xFFDFE8D6),
            tertiary: const Color(0xFFE0A76B),
            tertiaryContainer: const Color(0xFF5A3A1A),
            onTertiaryContainer: const Color(0xFFF4E4D0),
            surface: const Color(0xFF11191B),
            surfaceContainerLowest: const Color(0xFF0D1416),
            surfaceContainerLow: const Color(0xFF162023),
            surfaceContainer: const Color(0xFF1B2629),
            surfaceContainerHigh: const Color(0xFF223033),
            surfaceContainerHighest: const Color(0xFF2A393C),
            outlineVariant: const Color(0xFF34464A),
          );
    final text = Typography.material2021(platform: TargetPlatform.iOS).black.apply(fontFamilyFallback: const ['PingFang TC', 'Noto Sans TC']);
    RoundedRectangleBorder round(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.error, width: 2)),
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
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
