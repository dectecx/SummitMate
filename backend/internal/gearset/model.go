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
	ID          uuid.UUID         `json:"id" db:"id"`
	Title       string            `json:"title" db:"title"`
	Author      string            `json:"author" db:"author"`
	TotalWeight float64           `json:"total_weight" db:"total_weight"`
	ItemCount   int               `json:"item_count" db:"item_count"`
	Visibility  GearSetVisibility `json:"visibility" db:"visibility"`
	DownloadKey *string           `json:"download_key,omitempty" db:"download_key"`
	Items       []GearSetItem     `json:"items" db:"-"`
	Meals       []GearSetMeal     `json:"meals,omitempty" db:"-"`
	UserID      string            `json:"user_id" db:"user_id"`
	CreatedAt   time.Time         `json:"created_at" db:"created_at"`
	CreatedBy   string            `json:"created_by" db:"created_by"`
	UpdatedAt   time.Time         `json:"updated_at" db:"updated_at"`
	UpdatedBy   string            `json:"updated_by" db:"updated_by"`
}

type GearSetItem struct {
	ID         uuid.UUID `json:"id" db:"id"`
	GearSetID  uuid.UUID `json:"gear_set_id" db:"gear_set_id"`
	Name       string    `json:"name" db:"name"`
	Category   string    `json:"category" db:"category"`
	Weight     float64   `json:"weight" db:"weight"`
	Quantity   int       `json:"quantity" db:"quantity"`
	OrderIndex int       `json:"order_index" db:"order_index"`
}

// GearSetListFilter 封裝 Repository List 查詢條件，由 Service 組裝後傳入。
// OwnerID 不為 nil 時僅列出該擁有者的裝備組合（不限 visibility）。
// Visibilities 不為空時僅列出符合指定可見性的裝備組合。
// 兩者同時設定時以 AND 連接。
type GearSetListFilter struct {
	OwnerID      *string
	Visibilities []GearSetVisibility
}

type GearSetMeal struct {
	ID        uuid.UUID `json:"id" db:"id"`
	GearSetID uuid.UUID `json:"gear_set_id" db:"gear_set_id"`
	Day       string    `json:"day" db:"day"`
	MealType  string    `json:"meal_type" db:"meal_type"`
	Name      string    `json:"name" db:"name"`
	Calories  float64   `json:"calories" db:"calories"`
	Note      *string   `json:"note,omitempty" db:"note"`
}
