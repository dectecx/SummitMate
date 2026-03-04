package model

import "time"

// User represents a user entity in the database.
type User struct {
	ID                 string
	Email              string
	PasswordHash       string
	DisplayName        string
	Avatar             string
	RoleID             *string
	IsActive           bool
	IsVerified         bool
	VerificationCode   *string
	VerificationExpiry *time.Time
	LastLoginAt        *time.Time
	CreatedAt          time.Time
	UpdatedAt          time.Time
}
