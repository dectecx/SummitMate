import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../explore/domain/mountain_models.dart';
import '../explore/providers.dart';
import 'data/location_service.dart';
import 'domain/map_logic.dart';
import 'data/offline_manager.dart';
import 'providers.dart';

/// "地圖": the topographic map with the mountains, the person's position and the offline maps.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final _controller = MapController();
  LatLng? _me;
  bool _locating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final cam = _controller.camera;
    _controller.move(cam.center, (cam.zoom + delta).clamp(6, 18));
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case LocationFound(:final lat, :final lng):
        setState(() => _me = LatLng(lat, lng));
        _controller.move(LatLng(lat, lng), _controller.camera.zoom < 13 ? 13 : _controller.camera.zoom);
      case LocationDenied(:final permanent):
        _say(permanent ? '位置權限已被關閉，請到系統設定開啟。' : '需要位置權限才能顯示你的位置。');
      case LocationDisabled():
        _say('手機的定位服務沒有開啟。');
      case LocationUnavailable():
        _say('暫時抓不到位置，請到空曠處再試一次。');
    }
  }

  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final mountains = switch (ref.watch(mountainsProvider).value) {
      MountainsReady(:final data) => data.mountains,
      _ => const <Mountain>[],
    };
    final busy = (ref.watch(offlineRegionsProvider).value ?? const []).any((r) => r.state == OfflineState.downloading || r.state == OfflineState.queued);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('地圖'),
        actions: [
          IconButton(
            tooltip: '離線地圖',
            onPressed: () => context.push(Routes.offlineMaps),
            icon: Badge(isLabelVisible: busy, smallSize: 8, child: const Icon(Icons.download_for_offline_outlined)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: const MapOptions(initialCenter: LatLng(23.7, 121.0), initialZoom: 7.5, minZoom: 6, maxZoom: 18),
            children: [
              ref.watch(tileCacheProvider).buildTileLayer(),
              MarkerLayer(
                markers: [
                  for (final m in mountains)
                    Marker(
                      key: ValueKey('peak-${m.id}'),
                      point: LatLng(m.latitude, m.longitude),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => _onPeakTap(m, mountains),
                        child: Icon(Icons.landscape, color: scheme.primary, size: 24, shadows: const [Shadow(blurRadius: 4, color: Colors.white)]),
                      ),
                    ),
                  if (_me != null)
                    Marker(
                      key: const ValueKey('me'),
                      point: _me!,
                      width: 24,
                      height: 24,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Credit required by the data licence. It wraps (never overflows) and leaves room for the buttons.
          Positioned(
            left: 8,
            bottom: 8,
            right: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('地圖：內政部國土測繪中心（政府資料開放授權條款第 1 版）', style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ),
          // One control group so the buttons can never overlap each other or the attribution.
          Positioned(
            right: 12,
            bottom: 32,
            child: Material(
              elevation: 3,
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '我的位置',
                    onPressed: _locate,
                    icon: _locating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                  ),
                  const Divider(height: 1),
                  IconButton(tooltip: '放大', onPressed: () => _zoom(1), icon: const Icon(Icons.add)),
                  const Divider(height: 1),
                  IconButton(tooltip: '縮小', onPressed: () => _zoom(-1), icon: const Icon(Icons.remove)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPeakTap(Mountain m, List<Mountain> all) {
    final near = peaksNear(all, m.latitude, m.longitude, _controller.camera.zoom);
    if (near.length <= 1) return _showMountain(m);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8), child: Text('附近的山（${near.length}）', style: Theme.of(ctx).textTheme.titleLarge)),
            for (final p in near)
              ListTile(
                key: ValueKey('near-${p.id}'),
                title: Text(p.name),
                subtitle: Text('${p.region}  ·  ${p.elevation} m'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(Routes.mountain(p.id));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMountain(Mountain m) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(m.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${m.region}  ·  ${m.elevation} m'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(Routes.mountain(m.id));
              },
              child: const Text('查看山岳資料'),
            ),
          ],
        ),
      ),
    );
  }
}
