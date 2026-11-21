import 'package:material_ui/material_ui.dart';

import '../../shared/coming_soon.dart';

class TripsTab extends StatelessWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('行程')),
    body: const ComingSoon(icon: Icons.hiking, message: '行程功能即將推出'),
  );
}
