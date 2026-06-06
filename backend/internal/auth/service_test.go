package auth_test

import (
	"context"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"
	"summitmate/internal/auth/tokens"
	flagmocks "summitmate/internal/flag/mocks"
	"summitmate/pkg/cache"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestAuthService_Register(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given valid registration details, When registering, Then it creates user and returns tokens", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "test@example.com"
		password := "password123"
		displayName := "Test User"

		// Mock GetByEmail returns ErrNotFound (email doesn't exist)
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, auth.ErrNotFound)

		// Mock GetRoleIDByCode returns a role-123
		mockRepo.On("GetRoleIDByCode", mock.Anything, "MEMBER").Return("role-123", nil)

		// Mock Create success
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(u *auth.User) bool {
			return u.Email == email && u.DisplayName == displayName && *u.RoleID == "role-123"
		})).Return(&auth.User{ID: "user-123", Email: email, DisplayName: displayName, RoleCode: "MEMBER"}, nil)

		user, accessToken, refreshToken, err := svc.Register(context.Background(), email, password, displayName, nil)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, email, user.Email)
		assert.Equal(t, "MEMBER", user.RoleCode)
		assert.NotEmpty(t, accessToken)
		assert.NotEmpty(t, refreshToken)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given email already exists, When registering, Then it returns email already exists error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "existing@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(&auth.User{ID: "existing-id"}, nil)

		user, accessToken, refreshToken, err := svc.Register(context.Background(), email, "password123", "any", nil)

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrEmailExists, err)
		assert.Nil(t, user)
		assert.Empty(t, accessToken)
		assert.Empty(t, refreshToken)
	})

	t.Run("Given invalid email format, When registering, Then it returns invalid email error", func(t *testing.T) {
		svc := auth.NewAuthService(logger, nil, tokenManager, nil, nil, nil, secret)
		user, accessToken, refreshToken, err := svc.Register(context.Background(), "invalid-email", "password123", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrInvalidEmail, err)
		assert.Nil(t, user)
		assert.Empty(t, accessToken)
		assert.Empty(t, refreshToken)
	})

	t.Run("Given weak password, When registering, Then it returns weak password error", func(t *testing.T) {
		svc := auth.NewAuthService(logger, nil, tokenManager, nil, nil, nil, secret)

		// Too short
		_, _, _, err := svc.Register(context.Background(), "test@example.com", "short1", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrPasswordTooShort, err)

		// No letters
		_, _, _, err = svc.Register(context.Background(), "test@example.com", "12345678", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrPasswordTooWeak, err)

		// No numbers
		_, _, _, err = svc.Register(context.Background(), "test@example.com", "abcdefgh", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrPasswordTooWeak, err)
	})
}

func TestAuthService_Login(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given correct credentials, When logging in, Then it returns user profile and token", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "login@example.com"
		password := "correct-password"
		hashed, _ := auth.HashPassword(password)

		mockUser := &auth.User{
			ID:           "user-1",
			Email:        email,
			PasswordHash: hashed,
		}

		mockRepo.On("GetByEmail", mock.Anything, email).Return(mockUser, nil)

		user, accessToken, refreshToken, err := svc.Login(context.Background(), email, password)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, "user-1", user.ID)
		assert.NotEmpty(t, accessToken)
		assert.NotEmpty(t, refreshToken)
	})

	t.Run("Given incorrect credentials, When logging in, Then it returns invalid credentials error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "wrong@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, auth.ErrNotFound)

		user, accessToken, refreshToken, err := svc.Login(context.Background(), email, "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrInvalidCredentials, err)
		assert.Nil(t, user)
		assert.Empty(t, accessToken)
		assert.Empty(t, refreshToken)
	})
}

func TestAuthService_RefreshToken(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given valid refresh token, When refreshing token, Then it returns new access token", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		userID := "user-token"
		email := "token@example.com"
		oldToken, _ := tokenManager.GenerateToken(userID, email, "refresh", time.Hour)

		mockRepo.On("GetByID", mock.Anything, userID).Return(&auth.User{ID: userID, Email: email, IsActive: true}, nil)

		user, newAccessToken, newRefreshToken, err := svc.RefreshToken(context.Background(), oldToken)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.NotEmpty(t, newAccessToken)
		assert.NotEmpty(t, newRefreshToken)
		assert.NotEqual(t, oldToken, newRefreshToken)
	})
}
