package gearset

import (
	"time"

	"github.com/google/uuid"
)

type GearSetVisibility string

const (
	VisibilityPublic    GearSetVisibility = "public"
	VisibilityProtected GearSetVisibility = "protected"
	VisibilityPrivate   GearSetVisibility = "private"
)

// GearSet 對應資料庫 gear_sets 表的實體
type GearSet struct {
	ID          uuid.UUID         `json:"id"`
	Title       string            `json:"title"`
	Author      string            `json:"author"`
	TotalWeight float64           `json:"total_weight"`
	ItemCount   int               `json:"item_count"`
	Visibility  GearSetVisibility `json:"visibility"`
	DownloadKey *string           `json:"download_key,omitempty"`
	Items       []GearSetItem     `json:"items"`
	Meals       []GearSetMeal     `json:"meals,omitempty"`
	UserID      string            `json:"user_id"` // creator/owner
	CreatedAt   time.Time         `json:"created_at"`
	CreatedBy   string            `json:"created_by"`
	UpdatedAt   time.Time         `json:"updated_at"`
	UpdatedBy   string            `json:"updated_by"`
}

type GearSetItem struct {
	ID         uuid.UUID `json:"id"`
	GearSetID  uuid.UUID `json:"gear_set_id"`
	Name       string    `json:"name"`
	Category   string    `json:"category"`
	Weight     float64   `json:"weight"`
	Quantity   int       `json:"quantity"`
	OrderIndex int       `json:"order_index"`
}

type GearSetMeal struct {
	ID        uuid.UUID `json:"id"`
	GearSetID uuid.UUID `json:"gear_set_id"`
	Day       string    `json:"day"`
	MealType  string    `json:"meal_type"`
	Name      string    `json:"name"`
	Calories  float64   `json:"calories"`
	Note      *string   `json:"note,omitempty"`
}
