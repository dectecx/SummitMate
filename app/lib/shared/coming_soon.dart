import 'package:material_ui/material_ui.dart';

import 'brand/illustrations.dart';

/// The body of an empty or unavailable screen: a small picture (or an icon) and a short message.
/// Pass [illustration] where one fits; [icon] stays for the places that only need a symbol.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, this.icon, this.illustration, required this.message, this.action});
  final IconData? icon;
  final Illustration? illustration;
  final String message;

  /// An optional button under the message (e.g. "新增行程").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              IllustrationView(illustration!)
            else if (icon != null)
              Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
