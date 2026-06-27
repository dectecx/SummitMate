import 'package:injectable/injectable.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/core.dart';
import '../tools/log_service.dart';

/// 裝備庫同步服務 (Infrastructure)
///
/// 實作 [IGearLibrarySyncService]，封裝跨 Repository 的同步邏輯，
/// 將此業務規則從 Cubit 移出至 Domain Service 層。
@LazySingleton(as: IGearLibrarySyncService)
class GearLibrarySyncService implements IGearLibrarySyncService {
  static const String _source = 'GearLibrarySyncService';

  final IGearRepository _gearRepository;
  final ITripRepository _tripRepository;

  GearLibrarySyncService(this._gearRepository, this._tripRepository);

  @override
  Future<void> syncLinkedGear(GearLibraryItem libItem) async {
    final allGear = await _gearRepository.getAllItems();
    final linkedItems = allGear.where((g) => g.libraryItemId == libItem.id).toList();

    if (linkedItems.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final gear in linkedItems) {
      final tripResult = await _tripRepository.getTripById(gear.tripId);
      if (tripResult is Success) {
        final trip = (tripResult as Success).value;
        if (trip != null) {
          final isArchived = (trip.endDate != null && trip.endDate!.isBefore(today)) || !trip.isActive;
          if (isArchived) continue;
        }
      }

      bool changed = false;
      GearItem updatedGear = gear;

      if (gear.name != libItem.name) {
        updatedGear = updatedGear.copyWith(name: libItem.name);
        changed = true;
      }
      if (gear.weight != libItem.weight) {
        updatedGear = updatedGear.copyWith(weight: libItem.weight);
        changed = true;
      }
      if (gear.category != libItem.category) {
        updatedGear = updatedGear.copyWith(category: libItem.category);
        changed = true;
      }

      if (changed) {
        await _gearRepository.updateItem(updatedGear);
      }
    }

    LogService.info('已同步 ${linkedItems.length} 件連結裝備 (libraryItemId: ${libItem.id})', source: _source);
  }

  @override
  Future<List<LinkedTripInfo>> getLinkedTrips(String libraryItemId) async {
    final allGear = await _gearRepository.getAllItems();
    final linkedGear = allGear.where((g) => g.libraryItemId == libraryItemId).toList();

    final Set<String> tripIds = linkedGear.map((g) => g.tripId).whereType<String>().toSet();

    final List<LinkedTripInfo> result = [];
    for (final tid in tripIds) {
      final tripResult = await _tripRepository.getTripById(tid);
      if (tripResult is Success) {
        final trip = (tripResult as Success).value;
        if (trip != null) {
          result.add(LinkedTripInfo(tripId: trip.id, tripName: trip.name, startDate: trip.startDate));
        }
      }
    }
    return result;
  }
}
