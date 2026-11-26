import 'package:material_ui/material_ui.dart' show IconData, Icons;

/// Which of [count] cover scenes a trip gets. Derived from the id alone (FNV-1a), so every phone shows the same
/// one and nothing has to be stored. `String.hashCode` is not guaranteed to stay the same between versions.
int coverFor(String tripId, int count) {
  var hash = 0x811c9dc5;
  for (final unit in tripId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash % count;
}

/// The line icon of an itinerary node, guessed from its name.
IconData nodeIconFor(String name) {
  bool has(String pattern) => RegExp(pattern).hasMatch(name);
  if (has('登山口')) return Icons.flag_outlined;
  if (has('山屋|山莊|避難')) return Icons.cottage_outlined;
  if (has('營地|營位')) return Icons.holiday_village_outlined;
  if (has(r'水源|水塘|取水|池|湖|溪')) return Icons.water_drop_outlined;
  if (has(r'餐|午飯|晚飯')) return Icons.restaurant_outlined;
  if (has(r'峰|山頂|三角點|山$')) return Icons.terrain_outlined;
  return Icons.place_outlined;
}
