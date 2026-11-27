import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/brand/cover_image.dart';
import '../../app/router.dart';
import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../shared/animations.dart';
import '../../shared/brand/summit_logo.dart';
import '../../shared/icon_badge.dart';

/// Shown once, on first launch. One screen, two buttons, no carousel and nothing to skip.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final portrait = screen.height > screen.width;
    final animate = animationsOn(context, ref);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (portrait)
                    // the landscape settles into place once, then stays still
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: animate ? 0 : 1, end: 1),
                      duration: Duration(milliseconds: animate ? 900 : 0),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
                      ),
                      child: SizedBox(height: screen.height * .4, child: const CoverImage(cover: 0)),
                    )
                  else
                    SizedBox(height: MediaQuery.paddingOf(context).top + 24),
                  if (!portrait) const Center(child: SummitLogo(size: 72)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '山友 SummitMate',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '規劃行程、裝備與餐食，上山也能用',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 22),
                        const _Point(icon: Icons.explore_outlined, text: '沒有訊號也能查看與修改'),
                        const _Point(icon: Icons.backpack_outlined, text: '行程、裝備、餐食一次規劃'),
                        const _Point(icon: Icons.cloud_sync_outlined, text: '登入後自動備份，換手機不怕'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                    onPressed: () async {
                      await ref.read(settingsStoreProvider).setBool(SettingsStore.welcomeSeen, true);
                      if (context.mounted) context.go(Routes.trips);
                    },
                    child: const Text('開始使用'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.trips})),
                    child: const Text('登入或註冊'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        IconBadge(icon),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    ),
  );
}
