import '../../models/enums/sync_status.dart';
import '../../models/trip.dart';
import '../models/trip_api_models.dart';

/// Trip API Model ↔ Domain Model 轉換
class TripApiMapper {
  /// TripResponse → Trip (domain model)
  static Trip fromResponse(TripResponse response) {
    return Trip(
      id: response.id,
      userId: response.userId,
      name: response.name,
      description: response.description,
      startDate: response.startDate.toLocal(),
      endDate: response.endDate?.toLocal(),
      coverImage: response.coverImage,
      isActive: response.isActive,
      dayNames: response.dayNames,
      syncStatus: SyncStatus.synced,
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// TripListItemResponse → Trip (domain model)
  static Trip fromListItemResponse(TripListItemResponse response) {
    return Trip(
      id: response.id,
      userId: response.userId,
      name: response.name,
      description: '', // 列表不含描述
      startDate: response.startDate.toLocal(),
      endDate: response.endDate?.toLocal(),
      coverImage: response.coverImage,
      isActive: response.isActive,
      dayNames: const [], // 列表不含天數名稱
      syncStatus: SyncStatus.synced,
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// Trip (domain model) → TripCreateRequest
  static TripCreateRequest toCreateRequest(Trip trip) {
    return TripCreateRequest(
      name: trip.name,
      description: trip.description,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverImage: trip.coverImage,
      dayNames: trip.dayNames.isNotEmpty ? trip.dayNames : null,
    );
  }

  /// Trip (domain model) → TripUpdateRequest
  static TripUpdateRequest toUpdateRequest(Trip trip) {
    return TripUpdateRequest(
      name: trip.name,
      description: trip.description,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverImage: trip.coverImage,
      isActive: trip.isActive,
      dayNames: trip.dayNames,
      lastUpdatedAt: trip.updatedAt,
    );
  }
}
