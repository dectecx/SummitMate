package flag

import "time"

const (
	SkipVerificationCode = "skip_verification_code"
	EnableEmailSending   = "enable_email_sending"
)

type Flag struct {
	Key         string    `json:"key"`
	Value       bool      `json:"value"`
	Description string    `json:"description"`
	UpdatedAt   time.Time `json:"updated_at"`
}
