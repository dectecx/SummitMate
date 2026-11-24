import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../shared/brand/summit_logo.dart';

/// Shown once, on first launch. One screen, two buttons, no carousel and nothing to skip.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const SummitLogo(size: 96),
              const SizedBox(height: 16),
              Text('山友 SummitMate', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('規劃行程、裝備與糧食，上山也能用', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const Spacer(),
              const _Point(icon: Icons.signal_cellular_off, text: '沒有訊號也能查看與修改'),
              const _Point(icon: Icons.checklist, text: '行程、裝備、糧食一次規劃'),
              const _Point(icon: Icons.cloud_sync_outlined, text: '登入後自動備份，換手機不怕'),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () async {
                  await ref.read(settingsStoreProvider).setBool(SettingsStore.welcomeSeen, true);
                  if (context.mounted) context.go(Routes.trips);
                },
                child: const Text('開始使用'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.trips})),
                child: const Text('登入或註冊'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
