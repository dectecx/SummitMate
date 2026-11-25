import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../shared/brush_indicator.dart';
import '../shared/page_transitions.dart';

/// The "松林" palette of docs/ui/DESIGN_SYSTEM.md: pine teal for selection, coral for the one main action,
/// moss and sand for quiet highlights, all on warm paper.
/// Material 3, light and dark, large touch targets (used one-handed, outdoors), rounded shapes, flat cards.
abstract final class AppTheme {
  static const _seed = Color(0xFF2B6863);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final scheme = brightness == Brightness.light
        ? base.copyWith(
            primary: const Color(0xFF2B6863),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFCFE0CD),
            onPrimaryContainer: const Color(0xFF173B37),
            secondaryContainer: const Color(0xFFE1E9D6), // moss
            onSecondaryContainer: const Color(0xFF2A3826),
            tertiary: const Color(0xFFB4503D), // coral
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFF4E4CF), // sand
            onTertiaryContainer: const Color(0xFF4A2A0C),
            surface: const Color(0xFFF1EDE2), // paper
            surfaceContainerLowest: const Color(0xFFFFFDF8),
            surfaceContainerLow: const Color(0xFFF6F2E8),
            surfaceContainer: const Color(0xFFECE7DA),
            surfaceContainerHigh: const Color(0xFFE6E0D1),
            surfaceContainerHighest: const Color(0xFFE0D9C8),
            onSurface: const Color(0xFF3D342D),
            onSurfaceVariant: const Color(0xFF6C6055),
            outline: const Color(0xFF8F8273),
            outlineVariant: const Color(0xFFE4DCCB),
          )
        : base.copyWith(
            primary: const Color(0xFF8FCAC2),
            onPrimary: const Color(0xFF0D2B29),
            primaryContainer: const Color(0xFF27504B),
            onPrimaryContainer: const Color(0xFFD5ECE8),
            secondaryContainer: const Color(0xFF2A3628),
            onSecondaryContainer: const Color(0xFFDFE8D6),
            tertiary: const Color(0xFFEE9A84),
            onTertiary: const Color(0xFF3A130A),
            tertiaryContainer: const Color(0xFF3A3022),
            onTertiaryContainer: const Color(0xFFF4E4CF),
            surface: const Color(0xFF141C1D),
            surfaceContainerLowest: const Color(0xFF1F2A2B),
            surfaceContainerLow: const Color(0xFF1A2425),
            surfaceContainer: const Color(0xFF222E2F),
            surfaceContainerHigh: const Color(0xFF283536),
            surfaceContainerHighest: const Color(0xFF2F3D3F),
            onSurface: const Color(0xFFECE4D3),
            onSurfaceVariant: const Color(0xFFA9B0A8),
            outline: const Color(0xFF7D8A85),
            outlineVariant: const Color(0xFF324041),
          );
    final text = Typography.material2021(platform: TargetPlatform.iOS).black.apply(fontFamilyFallback: const ['PingFang TC', 'Noto Sans TC']);
    RoundedRectangleBorder round(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      // the paper and landscape come from the page transition, behind every scaffold
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: BackdropTransitionsBuilder.theme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        // a transparent bar cannot tell how dark the page is, so say it
        systemOverlayStyle: brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        color: scheme.surfaceContainerLowest,
        shadowColor: const Color(0x55503C23),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.error, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder(), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder(), side: BorderSide(color: scheme.outline))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: const StadiumBorder())),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.tertiary, foregroundColor: scheme.onTertiary, shape: const StadiumBorder()),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerLowest),
          foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BrushTabIndicator(scheme.tertiary),
        dividerColor: Colors.transparent,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      checkboxTheme: CheckboxThemeData(shape: const CircleBorder(), side: BorderSide(color: scheme.outline, width: 1.8)),
      progressIndicatorTheme: ProgressIndicatorThemeData(linearTrackColor: scheme.surfaceContainerHighest),
      listTileTheme: ListTileThemeData(shape: round(14)),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerLowest, shape: round(24), surfaceTintColor: Colors.transparent),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: round(16)),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
