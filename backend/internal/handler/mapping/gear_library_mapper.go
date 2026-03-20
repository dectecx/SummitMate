package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToGearLibraryItemResponse converts model.GearLibraryItem to api.GearLibraryItem
func ToGearLibraryItemResponse(item *model.GearLibraryItem) api.GearLibraryItem {
	return api.GearLibraryItem{
		Id:         uuid.MustParse(item.ID),
		UserId:     uuid.MustParse(item.UserID),
		Name:       item.Name,
		Weight:     item.Weight,
		Category:   item.Category,
		Notes:      item.Notes,
		IsArchived: item.IsArchived,
		CreatedAt:  item.CreatedAt,
		UpdatedAt:  item.UpdatedAt,
	}
}

// ToModelGearLibraryItem converts api.GearLibraryItemRequest to model.GearLibraryItem
func ToModelGearLibraryItem(req api.GearLibraryItemRequest) model.GearLibraryItem {
	isArchived := false
	if req.IsArchived != nil {
		isArchived = *req.IsArchived
	}
	return model.GearLibraryItem{
		Name:       req.Name,
		Weight:     req.Weight,
		Category:   req.Category,
		Notes:      req.Notes,
		IsArchived: isArchived,
	}
}

