import 'dart:convert';

/// One entry of a template or a shared set: a piece of gear or a meal item (see docs/architecture/GEAR_LIBRARY.md).
class SetItem {
  const SetItem({
    required this.kind,
    required this.name,
    this.category = 'other',
    this.weight = 0,
    this.quantity = 1,
    this.calories = 0,
    this.day = 1,
    this.note = '',
  });

  /// 'gear' or 'meal'.
  final String kind;
  final String name;

  /// Gear: a GearCategory key. Meal: a MealType key.
  final String category;

  /// Grams per unit.
  final double weight;
  final int quantity;

  /// Kcal per unit (meals).
  final double calories;

  /// Trip day, from 1 (meals).
  final int day;
  final String note;

  bool get isGear => kind == gearKind;
  bool get isMeal => kind == mealKind;

  static const gearKind = 'gear';
  static const mealKind = 'meal';

  Map<String, Object?> toJson() => {
    'kind': kind,
    'name': name,
    'category': category,
    'weight': weight,
    'quantity': quantity,
    if (isMeal) ...{'calories': calories, 'day': day},
    'note': note,
  };

  /// Null when [j] is not an item this version understands.
  static SetItem? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final kind = j['kind'];
    final name = j['name'];
    if ((kind != gearKind && kind != mealKind) || name is! String || name.trim().isEmpty) return null;
    double num0(Object? v) => v is num && v.isFinite && v >= 0 ? v.toDouble() : 0;
    int int1(Object? v, int fallback) => v is num && v.isFinite && v >= 0 ? v.toInt() : fallback;
    return SetItem(
      kind: kind as String,
      name: name.trim(),
      category: j['category'] is String ? j['category'] as String : 'other',
      weight: num0(j['weight']),
      quantity: int1(j['quantity'], 1),
      calories: num0(j['calories']),
      day: int1(j['day'], 1) < 1 ? 1 : int1(j['day'], 1),
      note: j['note'] is String ? j['note'] as String : '',
    );
  }
}

/// A set holds at most this many items (the server enforces the same limit).
const maxSetItems = 300;

String encodeSetItems(List<SetItem> items) => jsonEncode([for (final i in items.take(maxSetItems)) i.toJson()]);

/// Tolerant: entries this version does not understand are skipped, broken text gives an empty list.
List<SetItem> decodeSetItems(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    return [for (final e in raw) ?SetItem.tryFromJson(e)];
  } on Object {
    return const [];
  }
}

/// Total weight of the gear in grams (with quantities).
double gearWeightOf(List<SetItem> items) => items.where((i) => i.isGear).fold(0.0, (s, i) => s + i.weight * i.quantity);

int gearCountOf(List<SetItem> items) => items.where((i) => i.isGear).length;
int mealCountOf(List<SetItem> items) => items.where((i) => i.isMeal).length;
