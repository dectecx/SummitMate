package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToMealLibraryItemResponse converts model.MealLibraryItem to api.MealLibraryItem
func ToMealLibraryItemResponse(item *model.MealLibraryItem) api.MealLibraryItem {
	return api.MealLibraryItem{
		Id:         uuid.MustParse(item.ID),
		UserId:     uuid.MustParse(item.UserID),
		Name:       item.Name,
		Weight:     item.Weight,
		Calories:   item.Calories,
		Notes:      item.Notes,
		IsArchived: item.IsArchived,
		CreatedAt:  item.CreatedAt,
		UpdatedAt:  item.UpdatedAt,
	}
}

// ToModelMealLibraryItem converts api.MealLibraryItemRequest to model.MealLibraryItem
func ToModelMealLibraryItem(req api.MealLibraryItemRequest) model.MealLibraryItem {
	isArchived := false
	if req.IsArchived != nil {
		isArchived = *req.IsArchived
	}
	return model.MealLibraryItem{
		Name:       req.Name,
		Weight:     req.Weight,
		Calories:   req.Calories,
		Notes:      req.Notes,
		IsArchived: isArchived,
	}
}

