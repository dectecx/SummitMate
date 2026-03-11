package model

import "time"

type TripMealItem struct {
	ID            string    `json:"id" db:"id"`
	TripID        string    `json:"trip_id" db:"trip_id"`
	LibraryItemID *string   `json:"library_item_id" db:"library_item_id"`
	Day           string    `json:"day" db:"day"`
	MealType      string    `json:"meal_type" db:"meal_type"`
	Name          string    `json:"name" db:"name"`
	Weight        float64   `json:"weight" db:"weight"`
	Calories      float64   `json:"calories" db:"calories"`
	Quantity      int       `json:"quantity" db:"quantity"`
	Note          *string   `json:"note" db:"note"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	CreatedBy     string    `json:"created_by" db:"created_by"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy     string    `json:"updated_by" db:"updated_by"`
}
