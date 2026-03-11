package model

import "time"

type GearLibraryItem struct {
	ID         string    `json:"id" db:"id"`
	UserID     string    `json:"user_id" db:"user_id"`
	Name       string    `json:"name" db:"name"`
	Weight     float64   `json:"weight" db:"weight"`
	Category   string    `json:"category" db:"category"`
	Notes      *string   `json:"notes" db:"notes"`
	IsArchived bool      `json:"is_archived" db:"is_archived"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	CreatedBy  string    `json:"created_by" db:"created_by"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy  string    `json:"updated_by" db:"updated_by"`
}
