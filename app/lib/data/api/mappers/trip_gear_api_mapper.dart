import '../../../domain/entities/gear_item.dart';
import '../../models/gear_item_model.dart';
import '../models/trip_gear_api_models.dart';

/// TripGearItem API Model ↔ Data Model (Persistence) 轉換
class TripGearApiMapper {
  /// TripGearItemResponse → GearItemModel (data model)
  static GearItemModel fromResponse(TripGearItemResponse response) {
    return GearItemModel(
      id: response.id,
      tripId: response.tripId,
      libraryItemId: response.libraryItemId,
      name: response.name,
      weight: response.weight,
      category: response.category,
      quantity: response.quantity,
      isChecked: response.isChecked,
      orderIndex: response.orderIndex,
      createdAt: response.createdAt.toLocal(),
      updatedAt: response.updatedAt.toLocal(),
    );
  }

  /// GearItem (domain entity) → TripGearItemRequest
  static TripGearItemRequest toRequest(GearItem item) {
    return TripGearItemRequest(
      libraryItemId: item.libraryItemId,
      name: item.name,
      weight: item.weight,
      category: item.category,
      quantity: item.quantity,
      isChecked: item.isChecked,
      orderIndex: item.orderIndex,
    );
  }
}
