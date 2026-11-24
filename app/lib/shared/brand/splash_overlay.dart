import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'summit_logo.dart';

/// Whether the opening animation plays when the app starts. Tests turn it off.
final splashEnabledProvider = Provider<bool>((ref) => true);

/// Plays the SummitMate mark over the first screen when the app starts, then fades away.
/// The first screen is already built underneath, so nothing waits for the animation; a tap skips it.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with TickerProviderStateMixin {
  late final AnimationController _play = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _done = true;
      return;
    }
    _run();
  }

  Future<void> _run() async {
    await _play.forward();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _skip();
  }

  Future<void> _skip() async {
    if (_done || _fade.isAnimating || !mounted) return;
    await _fade.forward();
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _play.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: FadeTransition(
            opacity: ReverseAnimation(_fade),
            child: GestureDetector(
              key: const ValueKey('splash'),
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B6E92), Color(0xFF04436A)]),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _play,
                    builder: (context, _) {
                      final t = _play.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(opacity: Curves.easeOut.transform((t / 0.2).clamp(0, 1)), child: SummitLogo(size: 176, progress: t)),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: Curves.easeIn.transform(((t - 0.7) / 0.3).clamp(0, 1)),
                            child: const Text('SummitMate', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 1.5, decoration: TextDecoration.none)),
                          ),
                          const SizedBox(height: 6),
                          Opacity(
                            opacity: Curves.easeIn.transform(((t - 0.8) / 0.2).clamp(0, 1)),
                            child: const Text('山友', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 16, decoration: TextDecoration.none)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
