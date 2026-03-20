package dto

import "time"

// TripGearItemResponse is the API response DTO for trip gear items.
type TripGearItemResponse struct {
	ID            string    `json:"id"`
	TripID        string    `json:"trip_id"`
	LibraryItemID *string   `json:"library_item_id,omitempty"`
	Name          string    `json:"name"`
	Weight        float64   `json:"weight"`
	Category      string    `json:"category"`
	Quantity      int       `json:"quantity"`
	IsChecked     bool      `json:"is_checked"`
	OrderIndex    *int      `json:"order_index,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	CreatedBy     string    `json:"created_by"`
	UpdatedAt     time.Time `json:"updated_at"`
	UpdatedBy     string    `json:"updated_by"`
}
