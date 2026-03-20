package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToTripMealItemResponse converts model.TripMealItem to api.TripMealItem
func ToTripMealItemResponse(item *model.TripMealItem) api.TripMealItem {
	var libID *uuid.UUID
	if item.LibraryItemID != nil {
		parsed := uuid.MustParse(*item.LibraryItemID)
		libID = &parsed
	}

	return api.TripMealItem{
		Id:            uuid.MustParse(item.ID),
		TripId:        uuid.MustParse(item.TripID),
		LibraryItemId: libID,
		Day:           item.Day,
		MealType:      item.MealType,
		Name:          item.Name,
		Weight:        item.Weight,
		Calories:      item.Calories,
		Quantity:      item.Quantity,
		Note:          item.Note,
		CreatedAt:     item.CreatedAt,
		UpdatedAt:     item.UpdatedAt,
	}
}

// ToModelTripMealItem converts api.TripMealItemRequest to model.TripMealItem for service layer
func ToModelTripMealItem(req api.TripMealItemRequest) model.TripMealItem {
	var libIDStr *string
	if req.LibraryItemId != nil {
		s := req.LibraryItemId.String()
		libIDStr = &s
	}

	quantity := 1
	if req.Quantity != nil {
		quantity = *req.Quantity
	}

	return model.TripMealItem{
		LibraryItemID: libIDStr,
		Day:           req.Day,
		MealType:      req.MealType,
		Name:          req.Name,
		Weight:        req.Weight,
		Calories:      req.Calories,
		Quantity:      quantity,
		Note:          req.Note,
	}
}
