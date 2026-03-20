package model

import "time"

type GroupEvent struct {
	ID               string     `json:"id" db:"id"`
	Title            string     `json:"title" db:"title"`
	Description      string     `json:"description" db:"description"`
	Location         string     `json:"location" db:"location"`
	StartDate        time.Time  `json:"start_date" db:"start_date"`
	EndDate          *time.Time `json:"end_date" db:"end_date"`
	Status           string     `json:"status" db:"status"`
	MaxMembers       int        `json:"max_members" db:"max_members"`
	ApprovalRequired bool       `json:"approval_required" db:"approval_required"`
	PrivateMessage   string     `json:"private_message" db:"private_message"`
	LinkedTripID     *string    `json:"linked_trip_id" db:"linked_trip_id"`
	LikeCount        int        `json:"like_count" db:"like_count"`
	CommentCount     int        `json:"comment_count" db:"comment_count"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	CreatedBy        string     `json:"created_by" db:"created_by"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
	UpdatedBy        string     `json:"updated_by" db:"updated_by"`
}

type GroupEventApplication struct {
	ID        string    `json:"id" db:"id"`
	EventID   string    `json:"event_id" db:"event_id"`
	UserID    string    `json:"user_id" db:"user_id"`
	Status    string    `json:"status" db:"status"`
	Message   string    `json:"message" db:"message"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	CreatedBy string    `json:"created_by" db:"created_by"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy string    `json:"updated_by" db:"updated_by"`
}

type GroupEventComment struct {
	ID        string    `json:"id" db:"id"`
	EventID   string    `json:"event_id" db:"event_id"`
	UserID    string    `json:"user_id" db:"user_id"`
	Content   string    `json:"content" db:"content"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	CreatedBy string    `json:"created_by" db:"created_by"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy string    `json:"updated_by" db:"updated_by"`

	// Response-only: populated via JOIN on users table, not stored in group_event_comments
	DisplayName string `json:"display_name,omitempty" db:"-"`
	Avatar      string `json:"avatar,omitempty" db:"-"`
}

type GroupEventLike struct {
	EventID   string    `json:"event_id" db:"event_id"`
	UserID    string    `json:"user_id" db:"user_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	CreatedBy string    `json:"created_by" db:"created_by"`
}
