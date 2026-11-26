/// The data of a baked illustration (see `tool/art/generate.py`). Colours are roles, resolved by the theme.
library;

enum ArtColor {
  ink,
  paper,
  card,
  snow,
  rock,
  rockShade,
  sage,
  forest,
  forestShade,
  lake,
  lakeShade,
  sun,
  sunShade,
  accent,
  sand,
  tent,
  tentShade,
  glow,
  skyTop,
  skyMid,
  skyLow,
  rangeFar,
  peak,
  peakShade,
  hillBack,
  hillFront,
  pine,
  pineShade,
  wood,
  metal,
  ground,
  meadowFar,
  meadow,
  // watercolour effects
  edge,
  bloomLight,
  bloomDark,
}

/// The pictures of empty screens and the help.
enum ArtScene { trip, gear, meal, chat, map, friends, shop, search, help, star }

/// One paint step: filled polygons, stroked lines, or a soft blot of pigment.
class ArtOp {
  const ArtOp(this.color, {this.rings = const [], this.bloom, this.stroke = 0, this.alpha = 1, this.clip = -1});
  final ArtColor color;

  /// Flat x, y lists. Filled together with the non-zero rule, or stroked as open lines when [stroke] is set.
  final List<List<double>> rings;

  /// x, y, radius x, radius y, rotation (radians) of a soft blot.
  final List<double>? bloom;
  final double stroke;
  final double alpha;

  /// Index into [ArtDrawing.clips], or -1.
  final int clip;
}

class ArtDrawing {
  const ArtDrawing({required this.clips, required this.ops});
  final List<List<double>> clips;
  final List<ArtOp> ops;
}
