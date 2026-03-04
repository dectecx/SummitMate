package service

import (
	"context"
	"errors"
	"time"

	"summitmate/internal/auth"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

var (
	ErrEmailAlreadyExists = errors.New("email already exists")
	ErrInvalidCredentials = errors.New("invalid credentials")
)

type AuthService struct {
	userRepo *repository.UserRepository
	tokenMgr *auth.TokenManager
}

func NewAuthService(userRepo *repository.UserRepository, tokenMgr *auth.TokenManager) *AuthService {
	return &AuthService{
		userRepo: userRepo,
		tokenMgr: tokenMgr,
	}
}

// Register validates, hashes the password, creates a user, and returns their initial metadata and auth token.
func (s *AuthService) Register(ctx context.Context, email, password, displayName string) (*model.User, string, error) {
	// Check if email is already taken
	_, err := s.userRepo.GetByEmail(ctx, email)
	if err == nil {
		return nil, "", ErrEmailAlreadyExists
	}
	if !errors.Is(err, repository.ErrNotFound) {
		return nil, "", err // DB error
	}

	// Hash password
	hash, err := auth.HashPassword(password)
	if err != nil {
		return nil, "", err
	}

	userReq := &model.User{
		Email:        email,
		PasswordHash: hash,
		DisplayName:  displayName,
	}

	// Create user
	createdUser, err := s.userRepo.Create(ctx, userReq)
	if err != nil {
		return nil, "", err
	}

	// Generate JWT
	token, err := s.tokenMgr.GenerateToken(createdUser.ID, createdUser.Email, 24*time.Hour)
	if err != nil {
		return nil, "", err
	}

	return createdUser, token, nil
}

// Login verifies credentials and returns the user metadata and an auth token.
func (s *AuthService) Login(ctx context.Context, email, password string) (*model.User, string, error) {
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, "", ErrInvalidCredentials
		}
		return nil, "", err
	}

	if !auth.CheckPasswordHash(password, user.PasswordHash) {
		return nil, "", ErrInvalidCredentials
	}

	// Generate JWT
	token, err := s.tokenMgr.GenerateToken(user.ID, user.Email, 24*time.Hour)
	if err != nil {
		return nil, "", err
	}

	// TODO: Consider async updating last_login_at in the DB

	return user, token, nil
}

// GetUserByID gets a user by ID
func (s *AuthService) GetUserByID(ctx context.Context, id string) (*model.User, error) {
	return s.userRepo.GetByID(ctx, id)
}
