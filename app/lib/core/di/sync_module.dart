import 'package:injectable/injectable.dart';
import '../../domain/interfaces/i_sync_adapter.dart';
import '../../infrastructure/services/adapters/trip_sync_adapter.dart';
import '../../infrastructure/services/adapters/itinerary_sync_adapter.dart';
import '../../infrastructure/services/adapters/gear_sync_adapter.dart';
import '../../infrastructure/services/adapters/favorites_sync_adapter.dart';

/// 同步適配器註冊模組。
///
/// 提供 `SyncEngine` 編排用的 [ISyncAdapter] 清單。**清單順序即同步優先級**：
/// 父領域（行程本體）須排在子領域（節點、裝備）之前，確保 push/pull 正確。
/// 新增可同步領域時，在此清單加入對應 adapter 即可，無需改動 `SyncEngine`。
@module
abstract class SyncModule {
  @lazySingleton
  List<ISyncAdapter> syncAdapters(
    TripSyncAdapter trip,
    ItinerarySyncAdapter itinerary,
    GearSyncAdapter gear,
    FavoritesSyncAdapter favorites,
  ) => [trip, itinerary, gear, favorites];
}
