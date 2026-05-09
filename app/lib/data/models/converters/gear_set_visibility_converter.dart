import 'package:drift/drift.dart';
import '../../../domain/enums/gear_set_visibility.dart';

class GearSetVisibilityConverter extends TypeConverter<GearSetVisibility, String> {
  const GearSetVisibilityConverter();

  @override
  GearSetVisibility fromSql(String fromDb) {
    return GearSetVisibility.values.firstWhere(
      (v) => v.name == fromDb,
      orElse: () => GearSetVisibility.public,
    );
  }

  @override
  String toSql(GearSetVisibility value) {
    return value.name;
  }
}
