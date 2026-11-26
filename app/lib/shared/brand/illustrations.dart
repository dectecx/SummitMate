import 'package:material_ui/material_ui.dart';

import 'cover_image.dart';

/// The subjects of empty screens and the help.
enum Illustration { trip, gear, meal, chat, map, friends, shop, search, help, star }

/// A small watercolour for an empty screen: one of the covers with its edges melting into the page.
class IllustrationView extends StatelessWidget {
  const IllustrationView(this.kind, {super.key, this.width = 168});
  final Illustration kind;
  final double width;

  /// Which cover (see [CoverImage]) stands for each subject: hut 0, lake 1, clouds 2, camp 3, forest 4, summit 5.
  static int _coverOf(Illustration kind) => switch (kind) {
    Illustration.trip || Illustration.gear || Illustration.meal => 3,
    Illustration.chat || Illustration.friends => 0,
    Illustration.map || Illustration.help => 4,
    Illustration.shop || Illustration.search => 1,
    Illustration.star => 2,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width * 1.25,
    height: width * .9,
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => RadialGradient(
        radius: .5,
        colors: const [Colors.black, Colors.black, Colors.transparent],
        stops: const [0, .6, 1],
        transform: _Stretch(bounds.width / bounds.height),
      ).createShader(bounds),
      child: CoverImage(cover: _coverOf(kind)),
    ),
  );
}

/// Widens a circular gradient into an ellipse around the middle of its box.
class _Stretch extends GradientTransform {
  const _Stretch(this.x);
  final double x;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.identity()
    ..translateByDouble(bounds.center.dx, bounds.center.dy, 0, 1)
    ..scaleByDouble(x, 1, 1, 1)
    ..translateByDouble(-bounds.center.dx, -bounds.center.dy, 0, 1);
}
