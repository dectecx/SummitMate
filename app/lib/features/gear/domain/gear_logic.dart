import '../../../core/db/app_database.dart';

/// Gear categories. The key is what is stored and synced; the label is what the person sees.
enum GearCategory {
  sleep('sleep', '睡眠系統'),
  cook('cook', '炊具與飲水'),
  clothing('clothing', '衣物'),
  pack('pack', '背負與收納'),
  electronics('electronics', '電子與照明'),
  safety('safety', '安全與急救'),
  other('other', '其他');

  const GearCategory(this.key, this.label);
  final String key;
  final String label;

  /// Unknown keys (from a newer version or another client) fall back to [other].
  static GearCategory fromKey(String key) => values.firstWhere((c) => c.key == key, orElse: () => other);
}

/// Weights are stored in grams, calories in kcal.
String formatWeight(double grams) {
  if (grams < 1000) return '${grams == grams.roundToDouble() ? grams.toStringAsFixed(0) : grams.toStringAsFixed(1)} g';
  return '${(grams / 1000).toStringAsFixed(2)} kg';
}

/// Weight of an item times its quantity.
double lineWeight(GearItem i) => i.weight * i.quantity;

double totalWeight(Iterable<GearItem> items) => items.fold(0.0, (sum, i) => sum + lineWeight(i));

double packedWeight(Iterable<GearItem> items) => totalWeight(items.where((i) => i.isChecked));

int packedCount(Iterable<GearItem> items) => items.where((i) => i.isChecked).length;

/// Items grouped by category in the order of [GearCategory], each group ordered as the person added them.
/// Empty categories are left out.
List<({GearCategory category, List<GearItem> items})> groupGear(List<GearItem> all) {
  final groups = <GearCategory, List<GearItem>>{};
  for (final item in all) {
    groups.putIfAbsent(GearCategory.fromKey(item.category), () => []).add(item);
  }
  return [
    for (final c in GearCategory.values)
      if (groups[c] != null)
        (
          category: c,
          items: groups[c]!..sort((a, b) {
            final o = a.sortOrder.compareTo(b.sortOrder);
            return o != 0 ? o : a.name.compareTo(b.name);
          }),
        ),
  ];
}
