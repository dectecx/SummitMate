package dto

import "time"

// GroupEventResponse is the API response DTO for group events.
type GroupEventResponse struct {
	ID               string    `json:"id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	Location         string    `json:"location"`
	StartDate        string    `json:"start_date"`
	EndDate          *string   `json:"end_date,omitempty"`
	Status           string    `json:"status"`
	MaxMembers       int       `json:"max_members"`
	ApprovalRequired bool      `json:"approval_required"`
	PrivateMessage   string    `json:"private_message"`
	LinkedTripID     *string   `json:"linked_trip_id,omitempty"`
	LikeCount        int       `json:"like_count"`
	CommentCount     int       `json:"comment_count"`
	CreatedAt        time.Time `json:"created_at"`
	CreatedBy        string    `json:"created_by"`
	UpdatedAt        time.Time `json:"updated_at"`
	UpdatedBy        string    `json:"updated_by"`
}

// GroupEventApplicationResponse is the API response DTO for event applications.
type GroupEventApplicationResponse struct {
	ID        string    `json:"id"`
	EventID   string    `json:"event_id"`
	UserID    string    `json:"user_id"`
	Status    string    `json:"status"`
	Message   string    `json:"message"`
	CreatedAt time.Time `json:"created_at"`
	CreatedBy string    `json:"created_by"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy string    `json:"updated_by"`
}

// GroupEventCommentResponse is the API response DTO for event comments.
type GroupEventCommentResponse struct {
	ID          string    `json:"id"`
	EventID     string    `json:"event_id"`
	UserID      string    `json:"user_id"`
	Content     string    `json:"content"`
	DisplayName string    `json:"display_name,omitempty"`
	Avatar      string    `json:"avatar,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	CreatedBy   string    `json:"created_by"`
	UpdatedAt   time.Time `json:"updated_at"`
	UpdatedBy   string    `json:"updated_by"`
}
