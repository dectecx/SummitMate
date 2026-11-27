import 'package:material_ui/material_ui.dart';

/// The watercolour covers, with the part of each picture to keep when it is cropped.
const _covers = <(String, Alignment)>[
  ('hut', Alignment(0, .45)),
  ('lake', Alignment(0, .1)),
  ('clouds', Alignment(0, .55)),
  ('camp', Alignment(0, .4)),
  ('forest', Alignment(0, -.1)),
  ('summit', Alignment(0, .1)),
];

/// Takes some of the colour out of the pictures so they sit quietly beside the text.
const _saturation = .7;
const _calm = ColorFilter.matrix([
  .213 + .787 * _saturation, .715 - .715 * _saturation, .072 - .072 * _saturation, 0, 0, //
  .213 - .213 * _saturation, .715 + .285 * _saturation, .072 - .072 * _saturation, 0, 0,
  .213 - .213 * _saturation, .715 - .715 * _saturation, .072 + .928 * _saturation, 0, 0,
  0, 0, 0, 1, 0,
]);

/// How many covers there are to pick from.
int get coverCount => _covers.length;

/// A watercolour landscape filling its box. Dimmed in dark mode, which has no night pictures yet.
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.cover});

  /// Index of the picture, below [coverCount].
  final int cover;

  @override
  Widget build(BuildContext context) {
    final (name, alignment) = _covers[cover % _covers.length];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          // decode no larger than shown; a cropped box still needs the picture's own proportion (9:7)
          final width = box.maxWidth.isFinite ? box.maxWidth : 390.0;
          final height = box.maxHeight.isFinite ? box.maxHeight : 0.0;
          final needed = (width > height * 9 / 7 ? width : height * 9 / 7) * MediaQuery.devicePixelRatioOf(context);
          return ColorFiltered(
            colorFilter: _calm,
            child: Image.asset(
            'assets/covers/$name.webp',
            fit: BoxFit.cover,
            alignment: alignment,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: needed.ceil().clamp(1, 1152),
            gaplessPlayback: true,
            color: dark ? const Color(0x8C0F1A1B) : null,
            colorBlendMode: dark ? BlendMode.srcATop : null,
            ),
          );
        },
      ),
    );
  }
}
