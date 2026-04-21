package auth

import (
	"context"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth/tokens"
	"summitmate/internal/flag"
	"summitmate/pkg/cache"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestAuthService_Register(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Success", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		mockFlag := new(flag.MockService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "test@example.com"
		password := "password123"
		displayName := "Test User"

		// Mock GetByEmail returns ErrNotFound (email doesn't exist)
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, ErrNotFound)

		// Mock Create success
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(u *User) bool {
			return u.Email == email && u.DisplayName == displayName
		})).Return(&User{ID: "user-123", Email: email, DisplayName: displayName}, nil)

		user, token, err := svc.Register(context.Background(), email, password, displayName, nil)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, email, user.Email)
		assert.NotEmpty(t, token)
		mockRepo.AssertExpectations(t)
	})

	t.Run("EmailAlreadyExists", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		mockFlag := new(flag.MockService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "existing@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(&User{ID: "existing-id"}, nil)

		user, token, err := svc.Register(context.Background(), email, "any", "any", nil)

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrEmailExists, err)
		assert.Nil(t, user)
		assert.Empty(t, token)
	})
}

func TestAuthService_Login(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Success", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		mockFlag := new(flag.MockService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "login@example.com"
		password := "correct-password"
		hashed, _ := HashPassword(password)

		mockUser := &User{
			ID:           "user-1",
			Email:        email,
			PasswordHash: hashed,
		}

		mockRepo.On("GetByEmail", mock.Anything, email).Return(mockUser, nil)

		user, token, err := svc.Login(context.Background(), email, password)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, "user-1", user.ID)
		assert.NotEmpty(t, token)
	})

	t.Run("InvalidCredentials", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		mockFlag := new(flag.MockService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		email := "wrong@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, ErrNotFound)

		user, token, err := svc.Login(context.Background(), email, "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrInvalidCredentials, err)
		assert.Nil(t, user)
		assert.Empty(t, token)
	})
}

func TestAuthService_RefreshToken(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Success", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		mockFlag := new(flag.MockService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), mockFlag, secret)

		userID := "user-token"
		email := "token@example.com"
		oldToken, _ := tokenManager.GenerateToken(userID, email, time.Hour)

		mockRepo.On("GetByID", mock.Anything, userID).Return(&User{ID: userID, Email: email, IsActive: true}, nil)

		user, newToken, err := svc.RefreshToken(context.Background(), oldToken)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.NotEmpty(t, newToken)
		assert.NotEqual(t, oldToken, newToken)
	})
}
