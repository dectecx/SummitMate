package trip

import (
	"time"
)

// Trip 對應資料庫 trips 表的實體
type Trip struct {
	ID          string     `json:"id" db:"id"`
	UserID      string     `json:"user_id" db:"user_id"`
	Name        string     `json:"name" db:"name"`
	Description *string    `json:"description" db:"description"`
	StartDate   time.Time  `json:"start_date" db:"start_date"` // YYYY-MM-DD
	EndDate     *time.Time `json:"end_date" db:"end_date"`     // YYYY-MM-DD
	CoverImage  *string    `json:"cover_image" db:"cover_image"`
	IsActive    bool       `json:"is_active" db:"is_active"`
	DayNames    []string   `json:"day_names" db:"day_names"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	CreatedBy   string     `json:"created_by" db:"created_by"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
	UpdatedBy   string     `json:"updated_by" db:"updated_by"`
}

// TripMember 對應資料庫 trip_members 表的實體 (結合了 User 部分資訊)
type TripMember struct {
	TripID   string    `json:"trip_id" db:"trip_id"`
	UserID   string    `json:"user_id" db:"user_id"`
	JoinedAt time.Time `json:"joined_at" db:"joined_at"`
	// 以下來自 users 表的 JOIN 資訊
	UserEmail       string `json:"user_email" db:"email"`
	UserDisplayName string `json:"user_display_name" db:"display_name"`
	UserAvatar      string `json:"user_avatar" db:"avatar"`
}

// ItineraryItem 對應資料庫 itinerary_items 表的實體
type ItineraryItem struct {
	ID          string     `json:"id" db:"id"`
	TripID      string     `json:"trip_id" db:"trip_id"`
	Day         string     `json:"day" db:"day"`
	Name        string     `json:"name" db:"name"`
	EstTime     string     `json:"est_time" db:"est_time"`
	ActualTime  *time.Time `json:"actual_time" db:"actual_time"`
	Altitude    int32      `json:"altitude" db:"altitude"`
	Distance    float64    `json:"distance" db:"distance"`
	Note        string     `json:"note" db:"note"`
	ImageAsset  *string    `json:"image_asset" db:"image_asset"`
	IsCheckedIn bool       `json:"is_checked_in" db:"is_checked_in"`
	CheckedInAt *time.Time `json:"checked_in_at" db:"checked_in_at"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	CreatedBy   *string    `json:"created_by" db:"created_by"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
	UpdatedBy   *string    `json:"updated_by" db:"updated_by"`
}
