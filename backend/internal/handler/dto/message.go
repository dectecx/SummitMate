package dto

import "time"

// MessageResponse is the API response DTO for trip messages.
type MessageResponse struct {
	ID          string            `json:"id"`
	TripID      string            `json:"trip_id"`
	ParentID    *string           `json:"parent_id,omitempty"`
	UserID      string            `json:"user_id"`
	DisplayName string            `json:"display_name"`
	Avatar      string            `json:"avatar"`
	Category    string            `json:"category"`
	Content     string            `json:"content"`
	Timestamp   time.Time         `json:"timestamp"`
	Replies     []MessageResponse `json:"replies"`
	CreatedAt   time.Time         `json:"created_at"`
	CreatedBy   string            `json:"created_by"`
	UpdatedAt   time.Time         `json:"updated_at"`
	UpdatedBy   string            `json:"updated_by"`
}
