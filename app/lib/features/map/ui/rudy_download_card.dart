import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/offline_regions.dart';
import '../maplibre/rudy_providers.dart';
import '../rudy/rudy_constants.dart';
import '../rudy/rudy_installer.dart';

/// Download, use and remove the Rudy Map (登山地形圖). One file for the whole island, so it is a single card.
class RudyDownloadCard extends ConsumerWidget {
  const RudyDownloadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ready = ref.watch(rudyReadyProvider).value ?? false;
    final state = ref.watch(rudyInstallStateProvider).value;
    final installer = ref.watch(rudyInstallerProvider).value;
    final source = ref.watch(mapSourceProvider);
    final phase = state?.phase ?? RudyInstallPhase.idle;
    final busy = phase == RudyInstallPhase.probing || phase == RudyInstallPhase.downloadingMap || phase == RudyInstallPhase.downloadingFonts || phase == RudyInstallPhase.unpacking;

    Widget body;
    if (ready && !busy) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('已下載，山上沒訊號也能看。', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('rudy-use'),
            contentPadding: EdgeInsets.zero,
            title: const Text('地圖分頁使用魯地圖'),
            value: source == MapSource.rudy,
            onChanged: (v) => ref.read(mapSourceProvider.notifier).choose(v ? MapSource.rudy : MapSource.nlsc),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('rudy-remove'),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('刪除魯地圖？'),
                    content: const Text('會刪除手機上的魯地圖檔案，之後要用得重新下載。'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(88, 44), backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('刪除'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  if (source == MapSource.rudy) await ref.read(mapSourceProvider.notifier).choose(MapSource.nlsc);
                  await installer?.remove();
                  ref.invalidate(rudyReadyProvider); // the phase may not change (idle to idle), so check the files again
                }
              },
              child: const Text('刪除'),
            ),
          ),
        ],
      );
    } else if (busy) {
      final label = switch (phase) {
        RudyInstallPhase.probing => '正在確認檔案…',
        RudyInstallPhase.downloadingMap => '下載地圖中',
        RudyInstallPhase.downloadingFonts => '下載字型中',
        _ => '整理檔案中…',
      };
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(key: const ValueKey('rudy-progress'), value: phase == RudyInstallPhase.probing ? null : state!.progress),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(phase == RudyInstallPhase.probing ? label : '$label ${(state!.progress * 100).round()}%（${formatBytes(state.bytesDone.toDouble())}）')),
              TextButton(key: const ValueKey('rudy-cancel'), onPressed: () => installer?.cancel(), child: const Text('取消')),
            ],
          ),
        ],
      );
    } else {
      final message = switch (phase) {
        RudyInstallPhase.unavailable => state?.error ?? '魯地圖檔案目前還沒有開放下載。',
        RudyInstallPhase.failed => state?.error ?? '下載失敗，請檢查網路後再試。',
        _ => '登山專用地形圖：等高線、步道、山屋與山名。約 410 MB，建議使用 Wi-Fi，下載會在背景繼續進行。',
      };
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              key: const ValueKey('rudy-download'),
              onPressed: installer == null ? null : () => installer.start(),
              child: Text(phase == RudyInstallPhase.failed || phase == RudyInstallPhase.unavailable ? '重試' : '下載'),
            ),
          ),
        ],
      );
    }

    return Card(
      key: const ValueKey('rudy-card'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('魯地圖（登山地形圖）', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            body,
            const SizedBox(height: 8),
            Text(rudyAttribution, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
