import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';


/// The palette of docs/ui/DESIGN_SYSTEM.md: warm off-white paper, white cards, a deep pine for selection and one
/// burnt orange for the main action. Titles are set in Huninn, everything else in the system font.
/// Material 3, light and dark, large touch targets (used one-handed, outdoors), rounded shapes.
abstract final class AppTheme {
  static const _seed = Color(0xFF214E45);

  /// Titles; Huninn has one weight, so none is asked for.
  static const _title = TextStyle(fontFamily: 'Huninn', fontWeight: FontWeight.w400);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final scheme = brightness == Brightness.light
        ? base.copyWith(
            primary: const Color(0xFF214E45),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE3ECE8),
            onPrimaryContainer: const Color(0xFF17372F),
            secondaryContainer: const Color(0xFFE9EDE2), // moss
            onSecondaryContainer: const Color(0xFF2A3826),
            tertiary: const Color(0xFFB9532F), // coral
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFF7E7DD), // sand
            onTertiaryContainer: const Color(0xFF4A2A0C),
            surface: const Color(0xFFF6F4EF), // paper
            surfaceContainerLowest: const Color(0xFFFFFFFF),
            surfaceContainerLow: const Color(0xFFFBFAF7),
            surfaceContainer: const Color(0xFFF0EEE8),
            surfaceContainerHigh: const Color(0xFFEBE8E1),
            surfaceContainerHighest: const Color(0xFFE5E2DA),
            onSurface: const Color(0xFF1D2A27),
            onSurfaceVariant: const Color(0xFF5E6A66),
            outline: const Color(0xFF848E8A),
            outlineVariant: const Color(0xFFE8E4DA),
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
      scaffoldBackgroundColor: scheme.surface,
      textTheme: const TextTheme(headlineMedium: _title, headlineSmall: _title, titleLarge: _title, titleMedium: _title),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        systemOverlayStyle: brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.merge(_title).copyWith(fontSize: 24, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: scheme.surfaceContainerLowest,
        shadowColor: const Color(0x33192823),
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
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: scheme.primary, width: 3), borderRadius: BorderRadius.circular(2)),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      // docked at the bottom: white, with a pale capsule behind the current place
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      // The default range colour is too pale on paper to show which days are picked.
      datePickerTheme: DatePickerThemeData(rangeSelectionBackgroundColor: scheme.primary.withValues(alpha: brightness == Brightness.dark ? .45 : .24)),
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
