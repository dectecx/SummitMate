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
      if (row.rawJson != null) {
        return GearSet.fromJson(jsonDecode(row.rawJson!));
      }
      // 回退到從欄位構建 (如果沒有 rawJson)
      return GearSet(
        id: row.id,
        title: row.title,
        author: row.author,
        totalWeight: row.totalWeight,
        itemCount: row.itemCount,
        visibility: row.visibility,
        uploadedAt: row.uploadedAt,
        createdAt: row.createdAt,
        createdBy: row.createdBy,
        updatedAt: row.updatedAt,
        updatedBy: row.updatedBy,
      );
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
        sets
            .map(
              (s) => GearSetCacheTableCompanion.insert(
                id: s.id,
                title: s.title,
                author: s.author,
                totalWeight: Value(s.totalWeight),
                itemCount: Value(s.itemCount),
                visibility: s.visibility,
                uploadedAt: s.uploadedAt,
                createdAt: s.createdAt,
                createdBy: s.createdBy,
                updatedAt: s.updatedAt,
                updatedBy: s.updatedBy,
                rawJson: Value(jsonEncode(s.toJson())),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// 清空快取
  @override
  Future<void> clearCache() => delete(gearSetCacheTable).go();
}
