package dto

import "time"

// FavoriteResponse is the API response DTO for favorites.
type FavoriteResponse struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	TargetID  string    `json:"target_id"`
	Type      string    `json:"type"`
	CreatedAt time.Time `json:"created_at"`
	CreatedBy string    `json:"created_by"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy string    `json:"updated_by"`
}
