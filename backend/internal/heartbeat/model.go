package heartbeat

import "time"

// Heartbeat 對應資料庫 heartbeats 表的實體
type Heartbeat struct {
	UserID   string    `json:"user_id" db:"user_id"`
	UserType string    `json:"user_type" db:"user_type"`
	LastSeen time.Time `json:"last_seen" db:"last_seen"`
	View     string    `json:"view" db:"view"`
	Platform string    `json:"platform" db:"platform"`
}
