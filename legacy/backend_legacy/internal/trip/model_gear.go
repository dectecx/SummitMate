package trip

import "time"

type TripGearItem struct {
	ID            string    `json:"id" db:"id"`
	TripID        string    `json:"trip_id" db:"trip_id"`
	LibraryItemID *string   `json:"library_item_id" db:"library_item_id"`
	Name          string    `json:"name" db:"name"`
	Weight        float64   `json:"weight" db:"weight"`
	Category      string    `json:"category" db:"category"`
	Quantity      int       `json:"quantity" db:"quantity"`
	IsChecked     bool      `json:"is_checked" db:"is_checked"`
	OrderIndex    *int      `json:"order_index" db:"order_index"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	CreatedBy     string    `json:"created_by" db:"created_by"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy     string    `json:"updated_by" db:"updated_by"`
}
