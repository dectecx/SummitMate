import 'package:material_ui/material_ui.dart';

/// A titled group of rows inside one card (a gear category, a meal of the day): a caption row with an optional
/// figure on the right, thin dividers between the rows.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.title, this.trailing, required this.children});
  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.5))),
                  if (trailing != null) Text(trailing!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant),
              children[i],
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
