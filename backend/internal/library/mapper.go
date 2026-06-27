package library

import (
	"summitmate/api"

	"github.com/google/uuid"
)

// ToGearLibraryItemResponse converts GearLibraryItem to api.GearLibraryItem
func ToGearLibraryItemResponse(item *GearLibraryItem) api.GearLibraryItem {
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

// ToModelGearLibraryItem converts api.GearLibraryItemRequest to GearLibraryItem
func ToModelGearLibraryItem(req api.GearLibraryItemRequest) GearLibraryItem {
	isArchived := false
	if req.IsArchived != nil {
		isArchived = *req.IsArchived
	}
	return GearLibraryItem{
		Name:       req.Name,
		Weight:     req.Weight,
		Category:   req.Category,
		Notes:      req.Notes,
		IsArchived: isArchived,
	}
}

// ToModelGearLibraryItemFromAPI converts api.GearLibraryItem to GearLibraryItem for batch sync
func ToModelGearLibraryItemFromAPI(item api.GearLibraryItem) *GearLibraryItem {
	return &GearLibraryItem{
		ID:         item.Id.String(),
		UserID:     item.UserId.String(),
		Name:       item.Name,
		Weight:     item.Weight,
		Category:   item.Category,
		Notes:      item.Notes,
		IsArchived: item.IsArchived,
		CreatedAt:  item.CreatedAt,
		UpdatedAt:  item.UpdatedAt,
	}
}

// ToMealLibraryItemResponse converts MealLibraryItem to api.MealLibraryItem
func ToMealLibraryItemResponse(item *MealLibraryItem) api.MealLibraryItem {
	ingredients := item.Ingredients
	if ingredients == nil {
		ingredients = []string{}
	}
	return api.MealLibraryItem{
		Id:          uuid.MustParse(item.ID),
		UserId:      uuid.MustParse(item.UserID),
		Name:        item.Name,
		Weight:      item.Weight,
		Calories:    item.Calories,
		Category:    item.Category,
		Ingredients: ingredients,
		Notes:       item.Notes,
		IsArchived:  item.IsArchived,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}
}

// ToModelMealLibraryItem converts api.MealLibraryItemRequest to MealLibraryItem
func ToModelMealLibraryItem(req api.MealLibraryItemRequest) MealLibraryItem {
	isArchived := false
	if req.IsArchived != nil {
		isArchived = *req.IsArchived
	}
	category := "Other"
	if req.Category != nil && *req.Category != "" {
		category = *req.Category
	}
	ingredients := req.Ingredients
	if ingredients == nil {
		ingredients = []string{}
	}
	return MealLibraryItem{
		Name:        req.Name,
		Weight:      req.Weight,
		Calories:    req.Calories,
		Category:    category,
		Ingredients: ingredients,
		Notes:       req.Notes,
		IsArchived:  isArchived,
	}
}

// ToModelMealLibraryItemFromAPI converts api.MealLibraryItem to MealLibraryItem for batch sync
func ToModelMealLibraryItemFromAPI(item api.MealLibraryItem) *MealLibraryItem {
	ingredients := item.Ingredients
	if ingredients == nil {
		ingredients = []string{}
	}
	return &MealLibraryItem{
		ID:          item.Id.String(),
		UserID:      item.UserId.String(),
		Name:        item.Name,
		Weight:      item.Weight,
		Calories:    item.Calories,
		Category:    item.Category,
		Ingredients: ingredients,
		Notes:       item.Notes,
		IsArchived:  item.IsArchived,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}
}
