import '../../models/itinerary_item.dart';
import '../models/itinerary_api_models.dart';

/// ItineraryItem API Model ↔ Domain Model 轉換
class ItineraryApiMapper {
  /// ItineraryItemResponse → ItineraryItem (domain model)
  static ItineraryItem fromResponse(ItineraryItemResponse response) {
    return ItineraryItem(
      id: response.id,
      tripId: response.tripId,
      day: response.day,
      name: response.name,
      estTime: response.estTime,
      actualTime: response.actualTime?.toLocal(),
      altitude: response.altitude,
      distance: response.distance,
      note: response.note,
      imageAsset: response.imageAsset,
      isCheckedIn: response.isCheckedIn,
      checkedInAt: response.checkedInAt?.toLocal(),
      createdAt: response.createdAt.toLocal(),
      updatedAt: response.updatedAt.toLocal(),
    );
  }

  /// ItineraryItem (domain model) → ItineraryItemRequest
  static ItineraryItemRequest toRequest(ItineraryItem item) {
    return ItineraryItemRequest(
      day: item.day,
      name: item.name,
      estTime: item.estTime,
      altitude: item.altitude,
      distance: item.distance,
      note: item.note.isNotEmpty ? item.note : null,
      imageAsset: item.imageAsset,
    );
  }
}
