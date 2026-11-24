import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'rudy_download_card.dart';

/// "離線地圖": the Rudy Map download, the only map that works without a signal.
class OfflineMapsPage extends ConsumerWidget {
  const OfflineMapsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('離線地圖')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: const [RudyDownloadCard()],
      ),
    );
  }
}
