package model

import "time"

// TripMessage represents a message on the trip's discussion board.
// It includes embedded user information via SQL JOINs.
type TripMessage struct {
	ID          string         `json:"id" db:"id"`
	TripID      string         `json:"trip_id" db:"trip_id"`
	ParentID    *string        `json:"parent_id" db:"parent_id"`
	UserID      string         `json:"user_id" db:"user_id"`
	DisplayName string         `json:"display_name" db:"display_name"`
	Avatar      string         `json:"avatar" db:"avatar"`
	Category    string         `json:"category" db:"category"`
	Content     string         `json:"content" db:"content"`
	Timestamp   time.Time      `json:"timestamp" db:"timestamp"`
	Replies     []*TripMessage `json:"replies" db:"-"` // Handled in Service/Repo memory
	CreatedAt   time.Time      `json:"created_at" db:"created_at"`
	CreatedBy   string         `json:"created_by" db:"created_by"`
	UpdatedAt   time.Time      `json:"updated_at" db:"updated_at"`
	UpdatedBy   string         `json:"updated_by" db:"updated_by"`
}
