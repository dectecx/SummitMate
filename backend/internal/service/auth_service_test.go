package service

import (
	"context"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	"summitmate/internal/model"
	"summitmate/internal/repository"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestAuthService_Register(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := auth.NewTokenManager(secret)

	t.Run("Success", func(t *testing.T) {
		mockRepo := new(repository.MockUserRepository)
		svc := NewAuthService(logger, mockRepo, tokenManager, secret)

		email := "test@example.com"
		password := "password123"
		displayName := "Test User"

		// Mock GetByEmail returns ErrNotFound (email doesn't exist)
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, repository.ErrNotFound)

		// Mock Create success
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(u *model.User) bool {
			return u.Email == email && u.DisplayName == displayName
		})).Return(&model.User{ID: "user-123", Email: email, DisplayName: displayName}, nil)

		user, token, err := svc.Register(context.Background(), email, password, displayName)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, email, user.Email)
		assert.NotEmpty(t, token)
		mockRepo.AssertExpectations(t)
	})

	t.Run("EmailAlreadyExists", func(t *testing.T) {
		mockRepo := new(repository.MockUserRepository)
		svc := NewAuthService(logger, mockRepo, tokenManager, secret)

		email := "existing@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(&model.User{ID: "existing-id"}, nil)

		user, token, err := svc.Register(context.Background(), email, "any", "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrEmailExists, err)
		assert.Nil(t, user)
		assert.Empty(t, token)
	})
}

func TestAuthService_Login(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := auth.NewTokenManager(secret)

	t.Run("Success", func(t *testing.T) {
		mockRepo := new(repository.MockUserRepository)
		svc := NewAuthService(logger, mockRepo, tokenManager, secret)

		email := "login@example.com"
		password := "correct-password"
		hashed, _ := auth.HashPassword(password)

		mockUser := &model.User{
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
		mockRepo := new(repository.MockUserRepository)
		svc := NewAuthService(logger, mockRepo, tokenManager, secret)

		email := "wrong@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, repository.ErrNotFound)

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
	tokenManager := auth.NewTokenManager(secret)

	t.Run("Success", func(t *testing.T) {
		mockRepo := new(repository.MockUserRepository)
		svc := NewAuthService(logger, mockRepo, tokenManager, secret)

		userID := "user-token"
		email := "token@example.com"
		oldToken, _ := tokenManager.GenerateToken(userID, email, time.Hour)

		mockRepo.On("GetByID", mock.Anything, userID).Return(&model.User{ID: userID, Email: email, IsActive: true}, nil)

		user, newToken, err := svc.RefreshToken(context.Background(), oldToken)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.NotEmpty(t, newToken)
		assert.NotEqual(t, oldToken, newToken)
	})
}
