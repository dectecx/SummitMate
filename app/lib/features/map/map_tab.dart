import 'package:material_ui/material_ui.dart';

import '../../shared/coming_soon.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('地圖')),
    body: const ComingSoon(icon: Icons.map, message: '地圖與離線地圖即將推出'),
  );
}
