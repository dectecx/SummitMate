import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/brand/illustrations.dart';
import 'rudy_download_card.dart';

/// "離線地圖": the Rudy Map download, the only map that works without a signal.
class OfflineMapsPage extends ConsumerWidget {
  const OfflineMapsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('離線地圖')),
      body: ListView(
        padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          const SizedBox(height: 8),
          const Center(child: IllustrationView(Illustration.map)),
          const SizedBox(height: 8),
          Center(child: Text('把地圖帶上山', style: theme.textTheme.titleLarge)),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
            child: Column(
              children: [
                point(Icons.signal_cellular_off_outlined, '沒有訊號也能看等高線、步道、山屋與山名'),
                point(Icons.public_outlined, '一次下載整個台灣，不用挑區域'),
                point(Icons.wifi, '檔案較大，建議用 Wi-Fi，出發前先下載'),
              ],
            ),
          ),
          const RudyDownloadCard(),
        ],
      ),
    );
  }
}
