package favorite

import "time"

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
