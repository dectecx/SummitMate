package dto

import "time"

// TripResponse is the API response DTO for trips.
type TripResponse struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	Name        string    `json:"name"`
	Description *string   `json:"description,omitempty"`
	StartDate   string    `json:"start_date"`
	EndDate     *string   `json:"end_date,omitempty"`
	CoverImage  *string   `json:"cover_image,omitempty"`
	IsActive    bool      `json:"is_active"`
	DayNames    []string  `json:"day_names"`
	CreatedAt   time.Time `json:"created_at"`
	CreatedBy   string    `json:"created_by"`
	UpdatedAt   time.Time `json:"updated_at"`
	UpdatedBy   string    `json:"updated_by"`
}

// TripMemberResponse is the API response DTO for trip members.
type TripMemberResponse struct {
	TripID          string    `json:"trip_id"`
	UserID          string    `json:"user_id"`
	JoinedAt        time.Time `json:"joined_at"`
	UserEmail       string    `json:"user_email"`
	UserDisplayName string    `json:"user_display_name"`
	UserAvatar      string    `json:"user_avatar"`
}

// ItineraryItemResponse is the API response DTO for itinerary items.
type ItineraryItemResponse struct {
	ID          string     `json:"id"`
	TripID      string     `json:"trip_id"`
	Day         string     `json:"day"`
	Name        string     `json:"name"`
	EstTime     string     `json:"est_time"`
	ActualTime  *time.Time `json:"actual_time,omitempty"`
	Altitude    int32      `json:"altitude"`
	Distance    float64    `json:"distance"`
	Note        string     `json:"note"`
	ImageAsset  *string    `json:"image_asset,omitempty"`
	IsCheckedIn bool       `json:"is_checked_in"`
	CheckedInAt *time.Time `json:"checked_in_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	CreatedBy   *string    `json:"created_by,omitempty"`
	UpdatedAt   time.Time  `json:"updated_at"`
	UpdatedBy   *string    `json:"updated_by,omitempty"`
}
