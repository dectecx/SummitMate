import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../maplibre/rudy_providers.dart';

/// The parts floating over the map. Each corner has one job, so later tools have a place to go: top left what is on
/// the map, top right what the map shows (layers, routes, then the compass), bottom right where the person is,
/// bottom left the credit, and below those one card at a time (a route's height chart or an offer). See docs/ui/ONBOARDING_NAVIGATION.md.

/// The way into the map settings, saying which map is on screen.
class MapLayerButton extends StatelessWidget {
  const MapLayerButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '地圖設定',
      child: Material(
        key: const ValueKey('map-layers'),
        elevation: 3,
        shadowColor: Colors.black38,
        color: scheme.surfaceContainerLowest,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined, color: scheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurface)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round button over the map.
class MapRoundButton extends StatelessWidget {
  const MapRoundButton({super.key, required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      shadowColor: Colors.black38,
      color: scheme.surfaceContainerLowest,
      shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(foregroundColor: scheme.primary, minimumSize: const Size(48, 48)),
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}

/// Shown only while the map is turned: the needle points north, a tap turns north up again.
class MapCompass extends StatelessWidget {
  const MapCompass({super.key, required this.north, required this.onPressed});

  /// Where north points on screen, in degrees clockwise from straight up.
  final ValueListenable<double> north;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: north,
    builder: (context, degrees, _) {
      final turned = (degrees % 360 + 540) % 360 - 180; // -180..180
      if (turned.abs() < 1) return const SizedBox.shrink();
      return MapRoundButton(
        key: const ValueKey('map-compass'),
        tooltip: '轉回正北',
        onPressed: onPressed,
        icon: Transform.rotate(angle: turned * 3.141592653589793 / 180, child: const CustomPaint(size: Size.square(26), painter: _Needle())),
      );
    },
  );
}

class _Needle extends CustomPainter {
  const _Needle();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    Path half(double tip) => Path()
      ..moveTo(c.dx, tip)
      ..lineTo(c.dx + 5, c.dy)
      ..lineTo(c.dx - 5, c.dy)
      ..close();
    canvas
      ..drawPath(half(0), Paint()..color = const Color(0xFFC0392B))
      ..drawPath(half(size.height), Paint()..color = const Color(0xFF9AA5A1));
  }

  @override
  bool shouldRepaint(_Needle old) => false;
}

/// While the Rudy Map is wanted but not on the phone: why to get it, and the way to stop asking.
class RudyPrompt extends StatelessWidget {
  const RudyPrompt({super.key, required this.offline, required this.onDownload, required this.onDecline});
  final bool offline;
  final VoidCallback onDownload;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('rudy-prompt'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('下載魯地圖，沒有訊號也能看', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(offline ? '目前沒有網路，政府底圖無法載入。下次出發前先下載（約 410 MB）。' : '登山地形圖，約 410 MB，建議用 Wi-Fi。現在顯示的是需要網路的政府底圖。', style: theme.textTheme.bodySmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(key: const ValueKey('rudy-prompt-decline'), onPressed: onDecline, child: const Text('用政府底圖就好')),
                const SizedBox(width: 4),
                FilledButton(
                  key: const ValueKey('rudy-prompt-download'),
                  style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
                  onPressed: onDownload,
                  child: const Text('下載'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A route is chosen while the government map is on screen, which does not draw routes.
class RouteNeedsRudy extends StatelessWidget {
  const RouteNeedsRudy({super.key, required this.name, required this.installed, required this.onSwitch, required this.onClose});
  final String name;
  final bool installed;
  final VoidCallback onSwitch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('route-needs-rudy'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('路線只在魯地圖上顯示', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(installed ? '切換到魯地圖才看得到「$name」。' : '下載魯地圖（約 410 MB）後才看得到「$name」。', style: theme.textTheme.bodySmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(key: const ValueKey('route-close'), onPressed: onClose, child: const Text('不顯示路線')),
                const SizedBox(width: 4),
                FilledButton(
                  key: const ValueKey('route-switch'),
                  style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
                  onPressed: onSwitch,
                  child: Text(installed ? '切換魯地圖' : '下載'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The map settings panel: which map, the offline maps and where the map data comes from.
Future<void> showMapSettings(BuildContext context, {required ValueChanged<MapSource> onChoose, required VoidCallback onOfflineMaps, required VoidCallback onCredit}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) {
          final theme = Theme.of(context);
          final installed = ref.watch(rudyReadyProvider).value ?? false;
          final online = ref.watch(onlineProvider);
          final shown = ref.watch(shownMapProvider);
          Widget base(MapSource source, String key, String title, String note) {
            final on = shown == source;
            return Expanded(
              child: Semantics(
                button: true,
                selected: on,
                child: Card(
                  key: ValueKey(key),
                  color: on ? theme.colorScheme.primaryContainer : null,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheet);
                      onChoose(source);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                              if (on) Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(note, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('地圖設定', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        base(MapSource.rudy, 'base-rudy', '魯地圖', installed ? '登山地形圖，可離線' : '需先下載'),
                        const SizedBox(width: 12),
                        base(MapSource.nlsc, 'base-nlsc', '政府底圖', online ? '需要網路' : '目前沒有網路'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    key: const ValueKey('map-offline'),
                    leading: const Icon(Icons.download_for_offline_outlined),
                    title: const Text('離線地圖'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheet);
                      onOfflineMaps();
                    },
                  ),
                  ListTile(
                    key: const ValueKey('map-attribution'),
                    leading: const Icon(Icons.info_outline),
                    title: const Text('地圖資料來源'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheet);
                      onCredit();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
