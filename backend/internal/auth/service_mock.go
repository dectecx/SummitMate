package auth

import (
	"context"

	"github.com/stretchr/testify/mock"
)

type MockAuthService struct {
	mock.Mock
}

func (m *MockAuthService) Register(ctx context.Context, email, password, displayName string, avatar *string) (*User, string, string, error) {
	args := m.Called(ctx, email, password, displayName, avatar)
	if args.Get(0) == nil {
		return nil, "", "", args.Error(3)
	}
	return args.Get(0).(*User), args.String(1), args.String(2), args.Error(3)
}

func (m *MockAuthService) Login(ctx context.Context, email, password string) (*User, string, string, error) {
	args := m.Called(ctx, email, password)
	if args.Get(0) == nil {
		return nil, "", "", args.Error(3)
	}
	return args.Get(0).(*User), args.String(1), args.String(2), args.Error(3)
}

func (m *MockAuthService) GetUserByID(ctx context.Context, id string) (*User, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*User), args.Error(1)
}

func (m *MockAuthService) UpdateProfile(ctx context.Context, userID string, displayName, avatar *string) (*User, error) {
	args := m.Called(ctx, userID, displayName, avatar)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*User), args.Error(1)
}

func (m *MockAuthService) DeleteAccount(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

func (m *MockAuthService) RefreshToken(ctx context.Context, token string) (*User, string, string, error) {
	args := m.Called(ctx, token)
	if args.Get(0) == nil {
		return nil, "", "", args.Error(3)
	}
	return args.Get(0).(*User), args.String(1), args.String(2), args.Error(3)
}

func (m *MockAuthService) VerifyEmail(ctx context.Context, email, code string) error {
	args := m.Called(ctx, email, code)
	return args.Error(0)
}

func (m *MockAuthService) ResendVerificationCode(ctx context.Context, email string) error {
	args := m.Called(ctx, email)
	return args.Error(0)
}

func (m *MockAuthService) SearchUserByEmail(ctx context.Context, email string) (*User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*User), args.Error(1)
}
