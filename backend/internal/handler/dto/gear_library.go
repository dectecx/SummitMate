package dto

import "time"

// GearLibraryItemResponse is the API response DTO for gear library items.
type GearLibraryItemResponse struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	Name       string    `json:"name"`
	Weight     float64   `json:"weight"`
	Category   string    `json:"category"`
	Notes      *string   `json:"notes,omitempty"`
	IsArchived bool      `json:"is_archived"`
	CreatedAt  time.Time `json:"created_at"`
	CreatedBy  string    `json:"created_by"`
	UpdatedAt  time.Time `json:"updated_at"`
	UpdatedBy  string    `json:"updated_by"`
}
