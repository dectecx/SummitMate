import 'package:material_ui/material_ui.dart';

/// One day of a day selector: label over date.
class DayPill extends StatelessWidget {
  const DayPill({super.key, required this.label, required this.date, required this.selected, required this.onTap});
  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    '${date.month}/${date.day} ${_weekdays[date.weekday - 1]}',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The row of day pills above a day's list.
class DayBar extends StatelessWidget {
  const DayBar({super.key, required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      height: 26 + scaler.scale(13) * 1.4 + scaler.scale(11) * 1.4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Two or three equal pills that switch between views of one screen.
class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.labels, required this.selected, required this.onSelected, this.keys});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<Key>? keys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: Material(
                key: keys?[i],
                color: i == selected ? scheme.primary : scheme.surfaceContainerLowest,
                shape: StadiumBorder(side: BorderSide(color: i == selected ? scheme.primary : scheme.outlineVariant)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: i == selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
