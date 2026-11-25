import '../../../shared/brand/art/art_model.dart';

/// Which of [count] cover scenes a trip gets. Derived from the id alone (FNV-1a), so every phone shows the same
/// one and nothing has to be stored. `String.hashCode` is not guaranteed to stay the same between versions.
int coverFor(String tripId, int count) {
  var hash = 0x811c9dc5;
  for (final unit in tripId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash % count;
}

/// The picture for an itinerary node, guessed from its name; null when the name gives no clue.
ArtIcon? artIconFor(String name) {
  bool has(String pattern) => RegExp(pattern).hasMatch(name);
  if (has('登山口')) return ArtIcon.map;
  if (has('山屋|山莊|營地|營位|避難')) return ArtIcon.tent;
  if (has(r'水源|水塘|取水|池|湖|溪')) return ArtIcon.water;
  if (has(r'峰|山頂|三角點|山$')) return ArtIcon.summit;
  return null;
}
