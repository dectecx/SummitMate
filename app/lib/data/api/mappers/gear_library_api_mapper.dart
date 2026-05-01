import '../../models/gear_library_item_model.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/entities/gear_library_item.dart';
import '../models/gear_library_api_models.dart';

/// GearLibraryItem API Model ↔ Domain Model 轉換
class GearLibraryApiMapper {
  /// GearLibraryItemResponse → GearLibraryItemModel
  static GearLibraryItemModel fromResponse(GearLibraryItemResponse response) {
    return GearLibraryItemModel(
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

  /// GearLibraryItem (domain entity) → GearLibraryItemRequest
  static GearLibraryItemRequest toRequest(GearLibraryItem item) {
    return GearLibraryItemRequest(
      name: item.name,
      weight: item.weight,
      category: item.category,
      notes: item.notes,
      isArchived: item.isArchived,
    );
  }

  /// GearLibraryItemModel → GearLibraryItemRequest
  static GearLibraryItemRequest toRequestFromModel(GearLibraryItemModel model) {
    return GearLibraryItemRequest(
      name: model.name,
      weight: model.weight,
      category: model.category,
      notes: model.notes,
      isArchived: model.isArchived,
    );
  }
}
