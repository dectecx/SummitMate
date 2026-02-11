import 'package:hive/hive.dart';

part 'favorite_type.g.dart';

/// 最愛類型枚舉 (Enum)
@HiveType(typeId: 22)
enum FavoriteType {
  @HiveField(0)
  mountain('mountain'),
  @HiveField(1)
  route('route'),
  @HiveField(2)
  groupEvent('group_event'),
  @HiveField(3)
  other('other');

  final String value;
  const FavoriteType(this.value);

  static FavoriteType fromValue(String value) {
    return FavoriteType.values.firstWhere((e) => e.value == value, orElse: () => FavoriteType.other);
  }
}
