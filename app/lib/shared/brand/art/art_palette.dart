import 'package:material_ui/material_ui.dart';

import 'art_model.dart';

/// Colour of every art role. Two families: [scene] for covers, which turn into night scenes in dark mode, and
/// [object] for small pictures that sit on cards, whose outline must turn light on a dark card.
class ArtPalette {
  const ArtPalette._(this._colors);
  final Map<ArtColor, Color> _colors;

  Color operator [](ArtColor c) => _colors[c]!;

  static ArtPalette scene(ColorScheme s) =>
      ArtPalette._({..._base(s.brightness), ArtColor.paper: s.surface, if (s.brightness == Brightness.dark) ..._night});

  /// The app's mark keeps one set of colours everywhere, like the launcher icon.
  static final ArtPalette mark = ArtPalette._({..._base(Brightness.light), ArtColor.rock: const Color(0xFFA9856C), ArtColor.peak: const Color(0xFF8D7567)});

  static ArtPalette object(ColorScheme s) => ArtPalette._({
    ..._base(s.brightness),
    ArtColor.paper: s.surfaceContainerLowest,
    if (s.brightness == Brightness.dark) ..._dimObject,
  });

  static Map<ArtColor, Color> _base(Brightness brightness) => const {
    ArtColor.ink: Color(0xFF3D342D),
    ArtColor.paper: Color(0xFFF1EDE2),
    ArtColor.card: Color(0xFFFBF8F0),
    ArtColor.snow: Color(0xFFFBF9F3),
    ArtColor.rock: Color(0xFFA9856C),
    ArtColor.rockShade: Color(0xFF8A6A57),
    ArtColor.sage: Color(0xFF8FB07E),
    ArtColor.forest: Color(0xFF5C7F5B),
    ArtColor.forestShade: Color(0xFF46664A),
    ArtColor.lake: Color(0xFF8CC3D4),
    ArtColor.lakeShade: Color(0xFF5F9FB8),
    ArtColor.sun: Color(0xFFF2C94C),
    ArtColor.sunShade: Color(0xFFE0AB35),
    ArtColor.accent: Color(0xFFD9705A),
    ArtColor.sand: Color(0xFFE3D2AC),
    ArtColor.tent: Color(0xFFE3A04F),
    ArtColor.tentShade: Color(0xFF9D6F4B),
    ArtColor.glow: Color(0xFFF8DC8C),
    ArtColor.skyTop: Color(0xFF9FC3CC),
    ArtColor.skyMid: Color(0xFFEFCFA8),
    ArtColor.skyLow: Color(0xFFEEB08D),
    ArtColor.rangeFar: Color(0xFF8EA6B4),
    ArtColor.peak: Color(0xFF8D7567),
    ArtColor.peakShade: Color(0xFF735E55),
    ArtColor.hillBack: Color(0xFF7D9D77),
    ArtColor.hillFront: Color(0xFF5C7F5B),
    ArtColor.pine: Color(0xFF46664A),
    ArtColor.pineShade: Color(0xFF385440),
    ArtColor.wood: Color(0xFFB9875C),
    ArtColor.metal: Color(0xFF8A9AA3),
    ArtColor.ground: Color(0xFF2B6863),
    ArtColor.meadowFar: Color(0xFFC5D3C0),
    ArtColor.meadow: Color(0xFF9DB592),
    ArtColor.edge: Color(0xFF4A3526),
    ArtColor.bloomLight: Color(0xFFFFFAF0),
    ArtColor.bloomDark: Color(0xFF3D2F24),
  };

  static const _night = {
    ArtColor.ink: Color(0xFF10151A),
    ArtColor.snow: Color(0xFFB9C8D2),
    ArtColor.skyTop: Color(0xFF1D3340),
    ArtColor.skyMid: Color(0xFF2C4756),
    ArtColor.skyLow: Color(0xFF5A5266),
    ArtColor.rangeFar: Color(0xFF3D5668),
    ArtColor.peak: Color(0xFF4D4449),
    ArtColor.peakShade: Color(0xFF3B3438),
    ArtColor.hillBack: Color(0xFF34534A),
    ArtColor.hillFront: Color(0xFF27423A),
    ArtColor.pine: Color(0xFF1F352F),
    ArtColor.pineShade: Color(0xFF182A25),
    ArtColor.lake: Color(0xFF3F6A82),
    ArtColor.wood: Color(0xFF6B4F3A),
    ArtColor.metal: Color(0xFF4E5A60),
    ArtColor.accent: Color(0xFF8E4A3E),
    ArtColor.tent: Color(0xFF8C6838),
    ArtColor.tentShade: Color(0xFF523A29),
    ArtColor.glow: Color(0xFFF3D98A),
    ArtColor.bloomLight: Color(0x738FB0C8),
    ArtColor.meadowFar: Color(0xFF1C2D2B),
    ArtColor.meadow: Color(0xFF22392F),
  };

  static const _dimObject = {
    ArtColor.ink: Color(0xFFECE4D3),
    ArtColor.snow: Color(0xFFC8D0D2),
    ArtColor.rock: Color(0xFF80654F),
    ArtColor.sand: Color(0xFF8D805F),
    ArtColor.sage: Color(0xFF5D7C55),
    ArtColor.lake: Color(0xFF4F8296),
    ArtColor.tent: Color(0xFFB67D35),
    ArtColor.wood: Color(0xFF4A3426),
    ArtColor.accent: Color(0xFFC4705C),
    ArtColor.bloomLight: Color(0x4DFFFAF0),
  };
}
