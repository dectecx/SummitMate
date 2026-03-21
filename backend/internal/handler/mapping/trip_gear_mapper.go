package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToTripGearItemResponse converts model.TripGearItem to api.TripGearItem
func ToTripGearItemResponse(item *model.TripGearItem) api.TripGearItem {
	var libID *uuid.UUID
	if item.LibraryItemID != nil {
		parsed := uuid.MustParse(*item.LibraryItemID)
		libID = &parsed
	}

	return api.TripGearItem{
		Id:            uuid.MustParse(item.ID),
		TripId:        uuid.MustParse(item.TripID),
		LibraryItemId: libID,
		Name:          item.Name,
		Weight:        item.Weight,
		Category:      item.Category,
		Quantity:      item.Quantity,
		IsChecked:     item.IsChecked,
		OrderIndex:    item.OrderIndex,
		CreatedAt:     item.CreatedAt,
		UpdatedAt:     item.UpdatedAt,
	}
}

// ToModelTripGearItem converts api.TripGearItemRequest to model.TripGearItem for service layer
func ToModelTripGearItem(req api.TripGearItemRequest) model.TripGearItem {
	var libIDStr *string
	if req.LibraryItemId != nil {
		s := req.LibraryItemId.String()
		libIDStr = &s
	}

	quantity := 1
	if req.Quantity != nil {
		quantity = *req.Quantity
	}

	isChecked := false
	if req.IsChecked != nil {
		isChecked = *req.IsChecked
	}

	return model.TripGearItem{
		LibraryItemID: libIDStr,
		Name:          req.Name,
		Weight:        req.Weight,
		Category:      req.Category,
		Quantity:      quantity,
		IsChecked:     isChecked,
		OrderIndex:    req.OrderIndex,
	}
}

// ToModelTripGearItemFromAPI converts api.TripGearItem to model.TripGearItem for batch sync
func ToModelTripGearItemFromAPI(item api.TripGearItem) *model.TripGearItem {
	var libIDStr *string
	if item.LibraryItemId != nil {
		s := item.LibraryItemId.String()
		libIDStr = &s
	}

	return &model.TripGearItem{
		ID:            item.Id.String(),
		TripID:        item.TripId.String(),
		LibraryItemID: libIDStr,
		Name:          item.Name,
		Weight:        item.Weight,
		Category:      item.Category,
		Quantity:      item.Quantity,
		IsChecked:     item.IsChecked,
		OrderIndex:    item.OrderIndex,
		CreatedAt:     item.CreatedAt,
		UpdatedAt:     item.UpdatedAt,
	}
}
