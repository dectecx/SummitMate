package dto

import "time"

// TripMealItemResponse is the API response DTO for trip meal items.
type TripMealItemResponse struct {
	ID            string    `json:"id"`
	TripID        string    `json:"trip_id"`
	LibraryItemID *string   `json:"library_item_id,omitempty"`
	Day           string    `json:"day"`
	MealType      string    `json:"meal_type"`
	Name          string    `json:"name"`
	Weight        float64   `json:"weight"`
	Calories      float64   `json:"calories"`
	Quantity      int       `json:"quantity"`
	Note          *string   `json:"note,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	CreatedBy     string    `json:"created_by"`
	UpdatedAt     time.Time `json:"updated_at"`
	UpdatedBy     string    `json:"updated_by"`
}
