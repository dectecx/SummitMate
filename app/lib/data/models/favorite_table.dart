import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/enums/favorite_type.dart';
export '../../domain/enums/favorite_type.dart';

class FavoritesTable extends Table {
  TextColumn get id => text()();
  TextColumn get targetId => text()();

  // TODO: 確認 enum (FavoriteType) 在 DB 裡的儲存格式，此處以 index 儲存
  IntColumn get type => integer().map(const FavoriteTypeConverter())();

  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get updatedBy => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class FavoriteTypeConverter extends TypeConverter<FavoriteType, int> {
  const FavoriteTypeConverter();

  @override
  FavoriteType fromSql(int fromDb) {
    return FavoriteType.values.firstWhere((e) => e.index == fromDb, orElse: () => FavoriteType.mountain);
  }

  @override
  int toSql(FavoriteType value) {
    return value.index;
  }
}

extension FavoriteMapping on Favorite {
  FavoritesTableCompanion toCompanion() {
    return FavoritesTableCompanion.insert(
      id: id,
      targetId: targetId,
      type: type,
      createdAt: createdAt,
      createdBy: Value(createdBy),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
    );
  }
}
