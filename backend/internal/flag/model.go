package flag

import "time"

const (
	SkipVerificationCode = "skip_verification_code"
	EnableEmailSending   = "enable_email_sending"
)

// Flag 對應資料庫 system_flags 表的實體
type Flag struct {
	Key         string    `json:"key"`
	Value       bool      `json:"value"`
	Description string    `json:"description"`
	UpdatedAt   time.Time `json:"updated_at"`
}
