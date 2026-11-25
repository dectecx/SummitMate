import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/brand/art/art_view.dart';

/// One number of the info card, for example ("11.2 km", "距離").
typedef TripStat = ({String value, String label});

/// The head of a trip page. Opened, it is a full-bleed cover with a floating info card; scrolling washes the
/// cover out and leaves the title bar with the tabs pinned under it. See docs/ui/DESIGN_SYSTEM.md.
class TripHeaderDelegate extends SliverPersistentHeaderDelegate {
  TripHeaderDelegate({
    required this.cover,
    required this.title,
    required this.dates,
    required this.stats,
    required this.tabBar,
    required this.menu,
    required this.topPadding,
    required this.screen,
    required this.textScaler,
    required this.animate,
    required this.brightness,
  });

  final int cover;
  final String title;
  final String dates;
  final List<TripStat> stats;
  final PreferredSizeWidget tabBar;
  final Widget menu;
  final double topPadding;
  final Size screen;
  final TextScaler textScaler;

  /// Off: the header switches between its two looks halfway instead of blending.
  final bool animate;
  final Brightness brightness;

  static const _barHeight = 56.0;

  double get _infoHeight =>
      40 +
      textScaler.scale(24) * 1.4 +
      textScaler.scale(13) * 1.4 +
      textScaler.scale(16) * 1.4 +
      textScaler.scale(11) * 1.4;

  @override
  double get minExtent => topPadding + _barHeight + tabBar.preferredSize.height;

  @override
  double get maxExtent {
    // Wider than tall (a phone on its side), or too short for the card: the title bar only, so the list keeps its room.
    final art = math.min(430.0, screen.height * .5);
    final fits = screen.height > screen.width && art >= topPadding + _barHeight + _infoHeight;
    return fits ? art + tabBar.preferredSize.height : minExtent;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = tabBar.preferredSize.height;
    final range = maxExtent - minExtent;
    var s = math.min(shrinkOffset, range);
    if (range <= 0) {
      s = 0;
    } else if (!animate) {
      s = s < range / 2 ? 0 : range;
    }
    final t = range <= 0 ? 1.0 : s / range;
    double ramp(double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);
    final washed = ramp(0, .75);
    final info = 1 - ramp(.4, .65);
    final bar = ramp(.65, .9);
    final artHeight = math.max(maxExtent - tabs, minExtent - tabs);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ClipRect(
        child: ColoredBox(
          color: scheme.surface,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: -.3 * s,
                height: artHeight,
                child: Opacity(
                  opacity: 1 - .75 * washed,
                  child: CoverArt(cover: cover),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: minExtent,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: bar,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [.15, .8],
                          colors: [scheme.surface.withValues(alpha: 0), scheme.surface],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (maxExtent > minExtent)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: tabs + 6,
                  child: IgnorePointer(
                    ignoring: info == 0,
                    child: Opacity(
                      opacity: info,
                      child: _InfoCard(title: title, dates: dates, stats: stats),
                    ),
                  ),
                ),
              Positioned(
                left: 68,
                right: 68,
                top: topPadding,
                height: _barHeight,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    excluding: bar == 0,
                    child: Opacity(
                      opacity: maxExtent > minExtent ? bar : 1,
                      child: Center(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: topPadding + 4,
                child: const _RoundSurface(child: BackButton()),
              ),
              Positioned(
                right: 16,
                top: topPadding + 4,
                child: _RoundSurface(child: menu),
              ),
              Positioned(left: 0, right: 0, bottom: 0, height: tabs, child: tabBar),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(TripHeaderDelegate old) => true; // rebuilt only when the page itself rebuilds
}

class _RoundSurface extends StatelessWidget {
  const _RoundSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    shape: const CircleBorder(),
    elevation: 2,
    shadowColor: Colors.black38,
    child: SizedBox.square(dimension: 48, child: Center(child: child)),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.dates, required this.stats});
  final String title;
  final String dates;
  final List<TripStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.3);
    return Material(
      key: const ValueKey('trip-info-card'),
      color: scheme.surfaceContainerLowest,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            Text(dates, maxLines: 1, overflow: TextOverflow.ellipsis, style: small?.copyWith(fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final s in stats)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(s.label, style: small?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
