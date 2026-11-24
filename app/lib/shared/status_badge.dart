import 'package:material_ui/material_ui.dart';

/// A small tag that marks a feature that is not finished ("開發中") or still being tried out ("測試中"),
/// so it is clear at a glance which parts of the app are not done. Remove the tag when the feature is.
class StatusBadge extends StatelessWidget {
  const StatusBadge.inProgress({super.key}) : label = '開發中';
  const StatusBadge.testing({super.key}) : label = '測試中';
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onTertiaryContainer)),
      ),
    );
  }
}
