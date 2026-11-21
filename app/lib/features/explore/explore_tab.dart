import 'package:material_ui/material_ui.dart';

import '../../shared/coming_soon.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('探索')),
    body: const ComingSoon(icon: Icons.explore, message: '山岳資訊即將推出'),
  );
}
