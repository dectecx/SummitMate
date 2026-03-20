package dto

import "time"

// UserResponse is the API response DTO for user information.
type UserResponse struct {
	ID          string    `json:"id"`
	Email       string    `json:"email"`
	DisplayName string    `json:"display_name"`
	Avatar      string    `json:"avatar"`
	IsActive    bool      `json:"is_active"`
	IsVerified  bool      `json:"is_verified"`
	Role        string    `json:"role"`
	CreatedAt   time.Time `json:"created_at"`
	CreatedBy   *string   `json:"created_by,omitempty"`
	UpdatedAt   time.Time `json:"updated_at"`
	UpdatedBy   *string   `json:"updated_by,omitempty"`
}

// AuthResponse is the API response DTO for authentication endpoints.
type AuthResponse struct {
	Token string       `json:"token"`
	User  UserResponse `json:"user"`
}
