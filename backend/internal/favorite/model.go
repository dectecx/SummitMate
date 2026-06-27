package favorite

import "time"

// 收藏類型允許值，需與前端 FavoriteType enum 及 OpenAPI FavoriteType schema 保持一致。
const (
	TypeMountain   = "mountain"
	TypeGroupEvent = "group_event"
	TypeRoute      = "route"
	TypeOther      = "other"
)

// allowedTypes 為合法收藏類型集合，供 runtime 驗證使用。
var allowedTypes = map[string]struct{}{
	TypeMountain:   {},
	TypeGroupEvent: {},
	TypeRoute:      {},
	TypeOther:      {},
}

// IsValidType 回報傳入的收藏類型是否為允許值。
func IsValidType(t string) bool {
	_, ok := allowedTypes[t]
	return ok
}

type Favorite struct {
	ID        string    `json:"id" db:"id"`
	UserID    string    `json:"user_id" db:"user_id"`
	TargetID  string    `json:"target_id" db:"target_id"`
	Type      string    `json:"type" db:"type"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	CreatedBy string    `json:"created_by" db:"created_by"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy string    `json:"updated_by" db:"updated_by"`
}
