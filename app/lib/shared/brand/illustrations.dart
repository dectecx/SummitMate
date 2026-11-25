import 'package:material_ui/material_ui.dart';

import 'art/art_view.dart';

/// The pictures used on empty screens and in the help, in the app's hand-drawn style.
typedef Illustration = ArtScene;

class IllustrationView extends StatelessWidget {
  const IllustrationView(this.kind, {super.key, this.width = 168});
  final Illustration kind;
  final double width;

  @override
  Widget build(BuildContext context) => ArtSceneView(kind, width: width);
}
