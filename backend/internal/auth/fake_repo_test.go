package auth

import (
	"context"
	"sync"
	"time"

	"github.com/google/uuid"

	"summitmate/internal/store"
)

// fakeRepo is an in-memory Repository for service tests.
type fakeRepo struct {
	now            func() time.Time // stamps revocations
	mu             sync.Mutex
	users          map[uuid.UUID]store.User
	verifs         map[uuid.UUID]store.EmailVerification
	tokens         map[uuid.UUID]store.RefreshToken
	byHash         map[string]uuid.UUID
	friendsDeleted map[uuid.UUID]bool // users whose friendships were removed
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{
		now:            time.Now,
		users:          map[uuid.UUID]store.User{},
		verifs:         map[uuid.UUID]store.EmailVerification{},
		tokens:         map[uuid.UUID]store.RefreshToken{},
		byHash:         map[string]uuid.UUID{},
		friendsDeleted: map[uuid.UUID]bool{},
	}
}

func (f *fakeRepo) InTx(_ context.Context, fn func(Repository) error) error { return fn(f) }

func (f *fakeRepo) CreateUser(_ context.Context, a store.CreateUserParams) (store.User, error) {
	u := store.User{ID: uuid.New(), Email: a.Email, PasswordHash: a.PasswordHash, DisplayName: a.DisplayName, Avatar: a.Avatar, IsActive: true}
	f.users[u.ID] = u
	return u, nil
}

func (f *fakeRepo) GetUserByEmail(_ context.Context, email string) (store.User, error) {
	for _, u := range f.users {
		if u.Email == email {
			return u, nil
		}
	}
	return store.User{}, ErrNotFound
}

func (f *fakeRepo) GetUserByID(_ context.Context, id uuid.UUID) (store.User, error) {
	if u, ok := f.users[id]; ok {
		return u, nil
	}
	return store.User{}, ErrNotFound
}

func (f *fakeRepo) MarkUserVerified(_ context.Context, id uuid.UUID) error {
	u := f.users[id]
	u.IsVerified = true
	f.users[id] = u
	return nil
}

func (f *fakeRepo) TouchUserLogin(context.Context, uuid.UUID) error { return nil }

func (f *fakeRepo) UpdateUserProfile(_ context.Context, a store.UpdateUserProfileParams) (store.User, error) {
	u := f.users[a.ID]
	if a.DisplayName.Valid {
		u.DisplayName = a.DisplayName.String
	}
	if a.Avatar.Valid {
		u.Avatar = a.Avatar.String
	}
	f.users[a.ID] = u
	return u, nil
}

func (f *fakeRepo) UpdateUserPassword(_ context.Context, a store.UpdateUserPasswordParams) error {
	u := f.users[a.ID]
	u.PasswordHash = a.PasswordHash
	f.users[a.ID] = u
	return nil
}

func (f *fakeRepo) DeactivateUser(_ context.Context, id uuid.UUID) error {
	u := f.users[id]
	u.IsActive = false
	f.users[id] = u
	return nil
}

func (f *fakeRepo) DeleteFriendshipsOfUser(_ context.Context, id uuid.UUID) error {
	f.friendsDeleted[id] = true
	return nil
}

func (f *fakeRepo) UpsertVerification(_ context.Context, a store.UpsertVerificationParams) error {
	f.verifs[a.UserID] = store.EmailVerification{UserID: a.UserID, CodeHash: a.CodeHash, ExpiresAt: a.ExpiresAt}
	return nil
}

func (f *fakeRepo) GetVerification(_ context.Context, id uuid.UUID) (store.EmailVerification, error) {
	if v, ok := f.verifs[id]; ok {
		return v, nil
	}
	return store.EmailVerification{}, ErrNotFound
}

func (f *fakeRepo) IncrementVerificationAttempts(_ context.Context, id uuid.UUID) (int32, error) {
	v := f.verifs[id]
	v.Attempts++
	f.verifs[id] = v
	return v.Attempts, nil
}

func (f *fakeRepo) DeleteVerification(_ context.Context, id uuid.UUID) error {
	delete(f.verifs, id)
	return nil
}

func (f *fakeRepo) CreateRefreshToken(_ context.Context, a store.CreateRefreshTokenParams) (store.RefreshToken, error) {
	t := store.RefreshToken{ID: uuid.New(), UserID: a.UserID, TokenHash: a.TokenHash, ExpiresAt: a.ExpiresAt}
	f.tokens[t.ID] = t
	f.byHash[t.TokenHash] = t.ID
	return t, nil
}

func (f *fakeRepo) GetRefreshTokenByHash(_ context.Context, h string) (store.RefreshToken, error) {
	if id, ok := f.byHash[h]; ok {
		return f.tokens[id], nil
	}
	return store.RefreshToken{}, ErrNotFound
}

func (f *fakeRepo) RevokeRefreshToken(_ context.Context, a store.RevokeRefreshTokenParams) error {
	t := f.tokens[a.ID]
	if t.RevokedAt == nil {
		now := f.now()
		t.RevokedAt = &now
		t.ReplacedBy = a.ReplacedBy
		f.tokens[a.ID] = t
	}
	return nil
}

func (f *fakeRepo) RevokeAllRefreshTokens(_ context.Context, userID uuid.UUID) error {
	now := f.now()
	for id, t := range f.tokens {
		if t.UserID == userID && t.RevokedAt == nil {
			t.RevokedAt = &now
			f.tokens[id] = t
		}
	}
	return nil
}

func (f *fakeRepo) activeTokens(userID uuid.UUID) int {
	n := 0
	for _, t := range f.tokens {
		if t.UserID == userID && t.RevokedAt == nil {
			n++
		}
	}
	return n
}
