import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/brand/cover_image.dart';
import 'member_stack.dart';

/// One number of the trip's summary, for example ("11.2 km", "距離").
typedef TripStat = ({String value, String label});

/// The head of a trip page. Opened, it is the watercolour cover with a sheet over its lower edge holding the name,
/// who is coming and the main numbers; scrolling fades them away and leaves the title bar with the tabs pinned.
/// See docs/ui/DESIGN_SYSTEM.md.
class TripHeaderDelegate extends SliverPersistentHeaderDelegate {
  TripHeaderDelegate({
    required this.tripId,
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

  final String tripId;
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

  /// How far the sheet reaches up over the picture.
  static const _overlap = 24.0;

  double get _infoHeight => 20 + textScaler.scale(28) * 1.35 + textScaler.scale(13) * 1.4 + 12 + (24 + textScaler.scale(20) * 1.3 + textScaler.scale(11) * 1.4) + 8;

  @override
  double get minExtent => topPadding + _barHeight + tabBar.preferredSize.height;

  double get _artHeight => math.min(280.0, screen.height * .32);

  @override
  double get maxExtent {
    // Wider than tall (a phone on its side): the title bar only, so the list keeps its room.
    final full = _artHeight - _overlap + _infoHeight + tabBar.preferredSize.height;
    return screen.height > screen.width && full > minExtent ? full : minExtent;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
    final art = 1 - ramp(.2, .8);
    final info = 1 - ramp(.15, .55);
    final bar = ramp(.65, .9);
    final dark = brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ClipRect(
        child: ColoredBox(
          color: scheme.surface,
          child: Stack(
            children: [
              if (range > 0) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  top: -.3 * s,
                  height: _artHeight,
                  child: Opacity(opacity: art, child: CoverImage(cover: cover)),
                ),
                // a wash of paper keeps the status bar readable on the pale pictures
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: topPadding + 44,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [scheme.surface.withValues(alpha: .85), scheme.surface.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: tabs,
                  height: _infoHeight,
                  child: IgnorePointer(
                    ignoring: info == 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: info == 0 ? 0 : 1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Opacity(
                        opacity: info,
                        child: _Summary(tripId: tripId, title: title, dates: dates, stats: stats),
                      ),
                    ),
                  ),
                ),
              ],
              // the title bar's own paper, so nothing shows through behind the collapsed title
              Positioned(left: 0, right: 0, top: 0, height: topPadding + _barHeight, child: IgnorePointer(child: ColoredBox(color: scheme.surface.withValues(alpha: range > 0 ? bar : 1)))),
              Positioned(
                left: 72,
                right: 72,
                top: topPadding,
                height: _barHeight,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    excluding: range > 0 && bar == 0,
                    child: Opacity(
                      opacity: range > 0 ? bar : 1,
                      child: Center(
                        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, color: scheme.onSurface)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(left: 16, top: topPadding + 4, child: const _RoundSurface(child: BackButton())),
              Positioned(right: 16, top: topPadding + 4, child: _RoundSurface(child: menu)),
              Positioned(left: 0, right: 0, bottom: 0, height: tabs, child: ColoredBox(color: scheme.surface, child: tabBar)),
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
    elevation: 3,
    shadowColor: Colors.black38,
    child: SizedBox.square(dimension: 48, child: Center(child: child)),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.tripId, required this.title, required this.dates, required this.stats});
  final String tripId;
  final String title;
  final String dates;
  final List<TripStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4);
    return Padding(
      key: const ValueKey('trip-info-card'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28, height: 1.35, color: scheme.onSurface)),
                    Text(dates, maxLines: 1, overflow: TextOverflow.ellipsis, style: small?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              MemberStack(tripId: tripId),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Material(
              color: scheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: scheme.outlineVariant)),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) SizedBox(height: 32, child: VerticalDivider(width: 1, color: scheme.outlineVariant)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stats[i].value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                            Text(stats[i].label, maxLines: 1, style: small?.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
