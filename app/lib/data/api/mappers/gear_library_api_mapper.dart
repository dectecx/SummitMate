import '../../models/gear_library_item.dart';
import '../../models/enums/sync_status.dart';
import '../models/gear_library_api_models.dart';

/// GearLibraryItem API Model ↔ Domain Model 轉換
class GearLibraryApiMapper {
  /// GearLibraryItemResponse → GearLibraryItem (domain model)
  static GearLibraryItem fromResponse(GearLibraryItemResponse response) {
    return GearLibraryItem(
      id: response.id,
      userId: response.userId,
      name: response.name,
      weight: response.weight,
      category: response.category,
      notes: response.notes,
      isArchived: response.isArchived,
      syncStatus: SyncStatus.synced,
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// GearLibraryItem (domain model) → GearLibraryItemRequest
  static GearLibraryItemRequest toRequest(GearLibraryItem item) {
    return GearLibraryItemRequest(
      name: item.name,
      weight: item.weight,
      category: item.category,
      notes: item.notes,
      isArchived: item.isArchived,
    );
  }
}
