package dto

import "time"

// MealLibraryItemResponse is the API response DTO for meal library items.
type MealLibraryItemResponse struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	Name       string    `json:"name"`
	Weight     float64   `json:"weight"`
	Calories   float64   `json:"calories"`
	Notes      *string   `json:"notes,omitempty"`
	IsArchived bool      `json:"is_archived"`
	CreatedAt  time.Time `json:"created_at"`
	CreatedBy  string    `json:"created_by"`
	UpdatedAt  time.Time `json:"updated_at"`
	UpdatedBy  string    `json:"updated_by"`
}
