import 'package:material_ui/material_ui.dart';

/// The four pale colours that tell categories apart (docs/ui/DESIGN_SYSTEM.md). Text on them stays `onSurface`.
enum Tint {
  moss(Color(0xFFE1E9D6), Color(0xFF2A3628)),
  lake(Color(0xFFD8E8EA), Color(0xFF22363A)),
  sand(Color(0xFFF4E4CF), Color(0xFF3A3022)),
  rose(Color(0xFFF3DED7), Color(0xFF3A2926));

  const Tint(this.light, this.dark);
  final Color light;
  final Color dark;

  Color of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;
}
