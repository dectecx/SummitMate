package auth

import (
	"summitmate/api"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// ToUserResponse converts User to api.User
func ToUserResponse(user *User) api.User {
	role := user.RoleCode
	if role == "" {
		role = "MEMBER"
	}

	var createdBy *uuid.UUID
	if user.CreatedBy != nil {
		parsed := uuid.MustParse(*user.CreatedBy)
		createdBy = &parsed
	}
	var updatedBy *uuid.UUID
	if user.UpdatedBy != nil {
		parsed := uuid.MustParse(*user.UpdatedBy)
		updatedBy = &parsed
	}

	return api.User{
		Id:          uuid.MustParse(user.ID),
		Email:       openapi_types.Email(user.Email),
		DisplayName: user.DisplayName,
		Avatar:      user.Avatar,
		IsActive:    user.IsActive,
		IsVerified:  user.IsVerified,
		Role:        role,
		CreatedAt:   user.CreatedAt,
		CreatedBy:   createdBy,
		UpdatedAt:   user.UpdatedAt,
		UpdatedBy:   updatedBy,
	}
}

// ToAuthResponse converts model.User + token to api.AuthResponse
func ToAuthResponse(user *User, token string) api.AuthResponse {
	return api.AuthResponse{
		Token: token,
		User:  ToUserResponse(user),
	}
}
