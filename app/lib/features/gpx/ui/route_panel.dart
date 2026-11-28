import 'package:material_ui/material_ui.dart';

import '../domain/elevation_profile.dart';
import '../domain/track_route.dart';
import 'elevation_profile_chart.dart';
import 'route_format.dart';

/// The route on the map: its length and climb, and a height chart to drag along. [onPoint] tells the map which
/// point of the route to mark.
class RoutePanel extends StatefulWidget {
  const RoutePanel({super.key, required this.route, required this.onPoint, required this.onClose});
  final TrackRoute route;
  final ValueChanged<int?> onPoint;
  final VoidCallback onClose;

  @override
  State<RoutePanel> createState() => _RoutePanelState();
}

class _RoutePanelState extends State<RoutePanel> {
  bool _open = true;
  int? _index;
  late List<ProfilePoint> _profile = elevationProfile(widget.route.points);
  late ProfileStats? _stats = profileStats(widget.route.points);

  @override
  void didUpdateWidget(RoutePanel old) {
    super.didUpdateWidget(old);
    if (old.route != widget.route) {
      _index = null;
      _profile = elevationProfile(widget.route.points);
      _stats = profileStats(widget.route.points);
    }
  }

  void _scrub(double km) {
    final i = widget.route.indexAt(km);
    if (i == _index) return;
    setState(() => _index = i);
    widget.onPoint(i);
  }

  /// "2,860 m · 7.4 km · 3 小時 20 分"
  String _at(int i) {
    final route = widget.route;
    return [
      if (route.points[i].ele case final ele?) formatMetres(ele),
      formatKm(route.distancesKm[i]),
      if (route.elapsedAt(i) case final time?) formatElapsed(time),
    ].join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numbers = theme.textTheme.titleSmall;
    return Card(
      key: const ValueKey('route-panel'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.route.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall)),
                if (_profile.length >= 2)
                  IconButton(
                    key: const ValueKey('route-collapse'),
                    tooltip: _open ? '收合高度圖' : '展開高度圖',
                    onPressed: () => setState(() => _open = !_open),
                    icon: Icon(_open ? Icons.expand_more : Icons.expand_less),
                  ),
                IconButton(key: const ValueKey('route-close'), tooltip: '不顯示路線', onPressed: widget.onClose, icon: const Icon(Icons.close)),
              ],
            ),
            Wrap(
              spacing: 16,
              children: [
                Text(formatKm(widget.route.lengthKm), style: numbers),
                if (_stats case final s?) ...[
                  Text('↑ ${formatMetres(s.ascent)}', style: numbers),
                  Text('↓ ${formatMetres(s.descent)}', style: numbers),
                ] else
                  Text('這個檔案沒有海拔資料', style: theme.textTheme.bodySmall),
              ],
            ),
            if (_open && _profile.length >= 2) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 18,
                child: Text(
                  _index == null ? '在高度圖上拖曳，查看路線上的位置' : _at(_index!),
                  key: const ValueKey('route-cursor-label'),
                  style: _index == null ? theme.textTheme.bodySmall : theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevationProfileChart(
                  profile: _profile,
                  height: 110,
                  cursorKm: _index == null ? null : widget.route.distancesKm[_index!],
                  onScrub: _scrub,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
