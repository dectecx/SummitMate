import 'package:material_ui/material_ui.dart';

/// A titled group of rows in one rounded card, the layout of the "我" screen: a small caption above and
/// thin dividers between rows. Keeps long lists of links calm and scannable.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(title!, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1)),
            ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 64, color: theme.colorScheme.outlineVariant),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a [SettingsSection]: an icon in a soft round tile, a title, an optional subtitle and a chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.destructive = false, this.trailing});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;
    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: (destructive ? scheme.errorContainer : scheme.primaryContainer).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: destructive ? TextStyle(color: scheme.error) : null),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right, color: scheme.outline)),
    );
  }
}
