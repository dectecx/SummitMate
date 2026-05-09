import '../../../domain/entities/gear_set.dart';

abstract class IGearSetCacheLocalDataSource {
  Future<List<GearSet>> getAllGearSets();
  Future<void> saveGearSets(List<GearSet> sets);
  Future<void> clearCache();
}
