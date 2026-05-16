import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:summitmate/data/models/gear_set_cache_table.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/domain/entities/gear_set.dart';

import '../interfaces/i_gear_set_cache_local_data_source.dart';

part 'gear_set_cache_dao.g.dart';

@LazySingleton(as: IGearSetCacheLocalDataSource)
@DriftAccessor(tables: [GearSetCacheTable])
class GearSetCacheDao extends DatabaseAccessor<AppDatabase>
    with _$GearSetCacheDaoMixin
    implements IGearSetCacheLocalDataSource {
  GearSetCacheDao(AppDatabase db) : super(db);

  /// 取得所有快取的裝備組合
  @override
  Future<List<GearSet>> getAllGearSets() async {
    final rows = await select(gearSetCacheTable).get();
    return rows.map((row) {
      return GearSet.fromJson(jsonDecode(row.rawJson));
    }).toList();
  }

  /// 儲存/更新快取
  @override
  Future<void> saveGearSets(List<GearSet> sets) async {
    await batch((batch) {
      // 先清空舊的快取
      batch.deleteWhere(gearSetCacheTable, (t) => const Constant(true));

      batch.insertAll(
        gearSetCacheTable,
        sets.map((s) => GearSetCacheTableCompanion.insert(id: s.id, rawJson: jsonEncode(s.toJson()))).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// 清空快取
  @override
  Future<void> clearCache() => delete(gearSetCacheTable).go();
}
