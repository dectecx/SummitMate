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

	t.Run("Given valid registration details, When registering, Then it creates the user without issuing tokens", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), nil, mockFlag, secret, auth.DefaultDurations())

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

		user, err := svc.Register(context.Background(), email, password, displayName, nil)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, email, user.Email)
		assert.Equal(t, "MEMBER", user.RoleCode)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given email already exists, When registering, Then it returns email already exists error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), nil, mockFlag, secret, auth.DefaultDurations())

		email := "existing@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(&auth.User{ID: "existing-id"}, nil)

		user, err := svc.Register(context.Background(), email, "password123", "any", nil)

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrEmailExists, err)
		assert.Nil(t, user)
	})

	t.Run("Given invalid email format, When registering, Then it returns invalid email error", func(t *testing.T) {
		svc := auth.NewAuthService(logger, nil, tokenManager, nil, nil, nil, nil, secret, auth.DefaultDurations())
		user, err := svc.Register(context.Background(), "invalid-email", "password123", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrInvalidEmail, err)
		assert.Nil(t, user)
	})

	t.Run("Given weak password, When registering, Then it returns weak password error", func(t *testing.T) {
		svc := auth.NewAuthService(logger, nil, tokenManager, nil, nil, nil, nil, secret, auth.DefaultDurations())

		// Too short
		_, err := svc.Register(context.Background(), "test@example.com", "short1", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrPasswordTooShort, err)

		// No letters
		_, err = svc.Register(context.Background(), "test@example.com", "12345678", "any", nil)
		assert.Error(t, err)
		assert.Equal(t, apperror.ErrPasswordTooWeak, err)

		// No numbers
		_, err = svc.Register(context.Background(), "test@example.com", "abcdefgh", "any", nil)
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
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), nil, mockFlag, secret, auth.DefaultDurations())

		email := "login@example.com"
		password := "correct-password"
		hashed, _ := auth.HashPassword(password)

		mockUser := &auth.User{
			ID:           "user-1",
			Email:        email,
			PasswordHash: hashed,
			IsActive:     true,
			IsVerified:   true,
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
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), nil, mockFlag, secret, auth.DefaultDurations())

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

func TestAuthService_Login_RateLimit(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given repeated failed logins reach the limit, When logging in again, Then it returns too many requests error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockCache := cache.NewMemoryCache[string]()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)

		durations := auth.DefaultDurations()
		durations.LoginRateWindow = time.Minute
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, mockCache, nil, mockFlag, secret, durations)

		email := "ratelimit@example.com"
		hashed, _ := auth.HashPassword("correctPassword1")
		mockRepo.On("GetByEmail", mock.Anything, email).Return(
			&auth.User{ID: "user-rl", Email: email, PasswordHash: hashed, IsActive: true, IsVerified: true}, nil,
		)

		// 前 10 次：密碼錯誤
		for i := 0; i < 10; i++ {
			_, _, _, err := svc.Login(context.Background(), email, "wrongPassword")
			assert.ErrorIs(t, err, apperror.ErrInvalidCredentials)
		}

		// 第 11 次：即使密碼正確也被鎖定
		_, _, _, err := svc.Login(context.Background(), email, "correctPassword1")
		assert.ErrorIs(t, err, apperror.ErrTooManyRequests)
	})

	t.Run("Given many successful logins, When logging in again, Then the user is never locked out", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), nil, mockFlag, secret, auth.DefaultDurations())

		email := "frequent@example.com"
		hashed, _ := auth.HashPassword("correctPassword1")
		mockRepo.On("GetByEmail", mock.Anything, email).Return(
			&auth.User{ID: "user-f", Email: email, PasswordHash: hashed, IsActive: true, IsVerified: true}, nil,
		)

		for i := 0; i < 12; i++ {
			_, _, _, err := svc.Login(context.Background(), email, "correctPassword1")
			assert.NoError(t, err)
		}
	})

	t.Run("Given a successful login, When it follows some failures, Then the failure counter is cleared", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, cache.NewMemoryCache[string](), nil, mockFlag, secret, auth.DefaultDurations())

		email := "reset@example.com"
		hashed, _ := auth.HashPassword("correctPassword1")
		mockRepo.On("GetByEmail", mock.Anything, email).Return(
			&auth.User{ID: "user-r", Email: email, PasswordHash: hashed, IsActive: true, IsVerified: true}, nil,
		)

		for i := 0; i < 9; i++ {
			_, _, _, _ = svc.Login(context.Background(), email, "wrong")
		}
		_, _, _, err := svc.Login(context.Background(), email, "correctPassword1")
		assert.NoError(t, err)

		// 計數已清除：再失敗 9 次仍不會被鎖
		for i := 0; i < 9; i++ {
			_, _, _, err = svc.Login(context.Background(), email, "wrong")
			assert.ErrorIs(t, err, apperror.ErrInvalidCredentials)
		}
	})

	t.Run("Given cache is nil, When logging in, Then rate limit is skipped and login proceeds normally", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, nil, nil, mockFlag, secret, auth.DefaultDurations())

		email := "nocache@example.com"
		hashed, _ := auth.HashPassword("correctPassword1")
		mockRepo.On("GetByEmail", mock.Anything, email).Return(
			&auth.User{ID: "user-nc", Email: email, PasswordHash: hashed, IsActive: true, IsVerified: true}, nil,
		)

		_, _, _, err := svc.Login(context.Background(), email, "correctPassword1")
		assert.NoError(t, err)
	})
}

func TestAuthService_VerifyEmail_RateLimit(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given verify attempts exceed limit, When verifying again, Then it returns too many requests error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockCache := cache.NewMemoryCache[string]()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)

		durations := auth.DefaultDurations()
		durations.VerifyRateWindow = time.Minute
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, mockCache, nil, mockFlag, secret, durations)

		email := "verify@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(
			&auth.User{ID: "user-v", Email: email, IsVerified: false}, nil,
		)
		// 預存一個驗證碼讓前幾次通過到碼比對（碼錯誤，但不觸發限制）
		_ = mockCache.Set(context.Background(), cache.Key{Module: "auth", Domain: "verify", ID: email}, "999999", time.Minute)

		// 前 5 次：計數累積，碼錯誤但不觸發限制
		for i := 0; i < 5; i++ {
			err := svc.VerifyEmail(context.Background(), email, "000000")
			assert.ErrorIs(t, err, apperror.ErrInvalidVerificationCode)
		}

		// 第 6 次：觸發限制（在 DB 查詢之前）
		err := svc.VerifyEmail(context.Background(), email, "000000")
		assert.ErrorIs(t, err, apperror.ErrTooManyRequests)
	})

	t.Run("Given nil cache, When verify rate limit check fails, Then it fails open and proceeds normally", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)

		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, nil, nil, mockFlag, secret, auth.DefaultDurations())

		email := "nilcache@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, auth.ErrNotFound)

		// cache 為 nil 時應 fail-open，不回傳 ErrTooManyRequests
		err := svc.VerifyEmail(context.Background(), email, "000000")
		assert.NotErrorIs(t, err, apperror.ErrTooManyRequests)
	})
}

func TestAuthService_ResendVerificationCode_RateLimit(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given resend attempts exceed limit, When resending again, Then it returns too many requests error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockCache := cache.NewMemoryCache[string]()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)

		durations := auth.DefaultDurations()
		durations.ResendRateWindow = time.Minute
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, mockCache, nil, mockFlag, secret, durations)

		email := "resend@example.com"
		mockRepo.On("GetByEmail", mock.Anything, email).Return(
			&auth.User{ID: "user-rs", Email: email, IsVerified: false}, nil,
		)

		// 前 3 次：成功重發
		for i := 0; i < 3; i++ {
			err := svc.ResendVerificationCode(context.Background(), email)
			assert.NoError(t, err)
		}

		// 第 4 次：觸發限制
		err := svc.ResendVerificationCode(context.Background(), email)
		assert.ErrorIs(t, err, apperror.ErrTooManyRequests)
	})

	t.Run("Given rate limit reached with non-existent email, When resending, Then it returns too many requests without revealing user existence", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockCache := cache.NewMemoryCache[string]()
		mockFlag := new(flagmocks.MockFlagService)

		durations := auth.DefaultDurations()
		durations.ResendRateWindow = time.Minute
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, mockCache, nil, mockFlag, secret, durations)

		email := "ghost@example.com"

		// 先消耗完配額（不需要 email 存在）
		for i := 0; i < 3; i++ {
			mockRepo.On("GetByEmail", mock.Anything, email).Return(nil, auth.ErrNotFound).Once()
			_ = svc.ResendVerificationCode(context.Background(), email)
		}

		// 第 4 次：rate limit 在 DB 查詢之前觸發，不需要再 mock DB
		err := svc.ResendVerificationCode(context.Background(), email)
		assert.ErrorIs(t, err, apperror.ErrTooManyRequests)
		mockRepo.AssertExpectations(t)
	})
}

func TestAuthService_RefreshToken(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given valid refresh token, When refreshing token, Then it returns new tokens and blacklists old token", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockBlacklist := cache.NewMemoryTokenBlacklist()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, nil, mockBlacklist, mockFlag, secret, auth.DefaultDurations())

		userID := "user-token"
		email := "token@example.com"
		oldToken, _ := tokenManager.GenerateToken(userID, email, "refresh", time.Hour)

		mockRepo.On("GetByID", mock.Anything, userID).Return(&auth.User{ID: userID, Email: email, IsActive: true, IsVerified: true}, nil)

		user, newAccessToken, newRefreshToken, err := svc.RefreshToken(context.Background(), oldToken)

		assert.NoError(t, err)
		assert.NotNil(t, user)
		assert.NotEmpty(t, newAccessToken)
		assert.NotEmpty(t, newRefreshToken)
		assert.NotEqual(t, oldToken, newRefreshToken)

		// 舊 refresh token 應已加入黑名單
		revoked, blErr := mockBlacklist.IsRevoked(context.Background(), userID, oldToken, time.Now())
		assert.NoError(t, blErr)
		assert.True(t, revoked)
	})

	t.Run("Given already-used refresh token, When refreshing again, Then it returns unauthorized error", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockBlacklist := cache.NewMemoryTokenBlacklist()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, nil, mockBlacklist, mockFlag, secret, auth.DefaultDurations())

		userID := "user-token"
		email := "token@example.com"
		oldToken, _ := tokenManager.GenerateToken(userID, email, "refresh", time.Hour)

		mockRepo.On("GetByID", mock.Anything, userID).Return(&auth.User{ID: userID, Email: email, IsActive: true, IsVerified: true}, nil)

		// 第一次 refresh：成功，舊 token 被輪替入黑名單
		_, _, _, err := svc.RefreshToken(context.Background(), oldToken)
		assert.NoError(t, err)

		// 第二次以同一舊 token refresh：應被拒絕
		_, _, _, err = svc.RefreshToken(context.Background(), oldToken)
		assert.Error(t, err)
	})
}

func TestAuthService_Logout(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given valid token, When logging out, Then it blacklists the token", func(t *testing.T) {
		mockBlacklist := cache.NewMemoryTokenBlacklist()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, nil, tokenManager, nil, nil, mockBlacklist, mockFlag, secret, auth.DefaultDurations())

		userID := "user-token"
		email := "token@example.com"
		tokenStr, _ := tokenManager.GenerateToken(userID, email, "access", time.Hour)

		err := svc.Logout(context.Background(), tokenStr, "")
		assert.NoError(t, err)

		revoked, err := mockBlacklist.IsRevoked(context.Background(), userID, tokenStr, time.Now())
		assert.NoError(t, err)
		assert.True(t, revoked)
	})
}

func TestAuthService_ChangePassword(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	secret := "test-secret"
	tokenManager := tokens.NewTokenManager(secret)

	t.Run("Given correct old password and valid new password, When changing password, Then it updates database and revokes every existing token", func(t *testing.T) {
		mockRepo := new(authmocks.MockUserRepository)
		mockBlacklist := cache.NewMemoryTokenBlacklist()
		mockFlag := new(flagmocks.MockFlagService)
		mockFlag.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
		svc := auth.NewAuthService(logger, mockRepo, tokenManager, nil, nil, mockBlacklist, mockFlag, secret, auth.DefaultDurations())

		userID := "user-token"
		email := "token@example.com"
		oldPassword := "oldPassword123"
		newPassword := "newPassword456"

		hashedOld, _ := auth.HashPassword(oldPassword)
		mockUser := &auth.User{ID: userID, Email: email, PasswordHash: hashedOld}
		tokenStr, _ := tokenManager.GenerateToken(userID, email, "access", time.Hour)

		mockRepo.On("GetByID", mock.Anything, userID).Return(mockUser, nil)
		mockRepo.On("UpdatePassword", mock.Anything, userID, mock.AnythingOfType("string")).Return(nil)

		err := svc.ChangePassword(context.Background(), userID, oldPassword, newPassword)
		assert.NoError(t, err)

		// 所有既有 token（含 refresh token）都應失效
		revoked, err := mockBlacklist.IsRevoked(context.Background(), userID, tokenStr, time.Now().Add(-time.Minute))
		assert.NoError(t, err)
		assert.True(t, revoked)

		mockRepo.AssertExpectations(t)
	})
}

func newSessionTestService(t *testing.T, repo *authmocks.MockUserRepository) (auth.AuthService, cache.TokenBlacklist, *tokens.TokenManager) {
	t.Helper()
	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelError}))
	flags := new(flagmocks.MockFlagService)
	flags.On("IsEnabled", mock.Anything, mock.Anything).Return(false)
	manager := tokens.NewTokenManager("test-secret")
	blacklist := cache.NewMemoryTokenBlacklist()
	svc := auth.NewAuthService(logger, repo, manager, nil, cache.NewMemoryCache[string](), blacklist, flags, "test-secret", auth.DefaultDurations())
	return svc, blacklist, manager
}

func activeVerifiedUser(t *testing.T, email string) *auth.User {
	t.Helper()
	hash, err := auth.HashPassword("password123")
	assert.NoError(t, err)
	return &auth.User{ID: "u1", Email: email, PasswordHash: hash, IsActive: true, IsVerified: true}
}

func TestAuthService_Login_AccountState(t *testing.T) {
	t.Run("Given a disabled account with the right password, When logging in, Then it is rejected", func(t *testing.T) {
		repo := new(authmocks.MockUserRepository)
		user := activeVerifiedUser(t, "a@example.com")
		user.IsActive = false
		repo.On("GetByEmail", mock.Anything, "a@example.com").Return(user, nil)
		svc, _, _ := newSessionTestService(t, repo)

		_, access, refresh, err := svc.Login(context.Background(), "a@example.com", "password123")

		assert.ErrorIs(t, err, apperror.ErrAccountDisabled)
		assert.Empty(t, access)
		assert.Empty(t, refresh)
	})

	t.Run("Given an unverified account with the right password, When logging in, Then no token is issued", func(t *testing.T) {
		repo := new(authmocks.MockUserRepository)
		user := activeVerifiedUser(t, "a@example.com")
		user.IsVerified = false
		repo.On("GetByEmail", mock.Anything, "a@example.com").Return(user, nil)
		svc, _, _ := newSessionTestService(t, repo)

		_, access, refresh, err := svc.Login(context.Background(), "a@example.com", "password123")

		assert.ErrorIs(t, err, apperror.ErrEmailNotVerified)
		assert.Empty(t, access)
		assert.Empty(t, refresh)
	})

	t.Run("Given a disabled account with a wrong password, When logging in, Then the account state is not revealed", func(t *testing.T) {
		repo := new(authmocks.MockUserRepository)
		user := activeVerifiedUser(t, "a@example.com")
		user.IsActive = false
		repo.On("GetByEmail", mock.Anything, "a@example.com").Return(user, nil)
		svc, _, _ := newSessionTestService(t, repo)

		_, _, _, err := svc.Login(context.Background(), "a@example.com", "wrong-password")

		assert.ErrorIs(t, err, apperror.ErrInvalidCredentials)
	})

	t.Run("Given an unverified user holding a refresh token, When refreshing, Then it is rejected", func(t *testing.T) {
		repo := new(authmocks.MockUserRepository)
		user := activeVerifiedUser(t, "a@example.com")
		user.IsVerified = false
		repo.On("GetByID", mock.Anything, "u1").Return(user, nil)
		svc, _, manager := newSessionTestService(t, repo)
		refresh, _ := manager.GenerateToken("u1", "a@example.com", "refresh", time.Hour)

		_, _, _, err := svc.RefreshToken(context.Background(), refresh)

		assert.ErrorIs(t, err, apperror.ErrEmailNotVerified)
	})
}

func TestAuthService_Login_EmailNormalization(t *testing.T) {
	t.Run("Given a mixed-case email with spaces, When logging in, Then the repository is queried with the normalized email", func(t *testing.T) {
		repo := new(authmocks.MockUserRepository)
		repo.On("GetByEmail", mock.Anything, "a@example.com").Return(activeVerifiedUser(t, "a@example.com"), nil)
		svc, _, _ := newSessionTestService(t, repo)

		_, access, _, err := svc.Login(context.Background(), "  A@Example.COM ", "password123")

		assert.NoError(t, err)
		assert.NotEmpty(t, access)
		repo.AssertExpectations(t)
	})

	t.Run("Given case variants of one email, When failing to log in, Then they share one rate limit counter", func(t *testing.T) {
		repo := new(authmocks.MockUserRepository)
		repo.On("GetByEmail", mock.Anything, "a@example.com").Return(activeVerifiedUser(t, "a@example.com"), nil)
		svc, _, _ := newSessionTestService(t, repo)

		variants := []string{"a@example.com", "A@example.com", "a@EXAMPLE.com", "A@EXAMPLE.COM", " a@example.com"}
		for i := 0; i < 10; i++ {
			_, _, _, _ = svc.Login(context.Background(), variants[i%len(variants)], "wrong")
		}

		_, _, _, err := svc.Login(context.Background(), "A@Example.com", "password123")
		assert.ErrorIs(t, err, apperror.ErrTooManyRequests)
	})
}

func TestAuthService_SessionRevocation(t *testing.T) {
	login := func(t *testing.T) (auth.AuthService, cache.TokenBlacklist, string, string, *authmocks.MockUserRepository) {
		repo := new(authmocks.MockUserRepository)
		user := activeVerifiedUser(t, "a@example.com")
		repo.On("GetByEmail", mock.Anything, "a@example.com").Return(user, nil)
		repo.On("GetByID", mock.Anything, "u1").Return(user, nil)
		svc, bl, _ := newSessionTestService(t, repo)
		_, access, refresh, err := svc.Login(context.Background(), "a@example.com", "password123")
		assert.NoError(t, err)
		return svc, bl, access, refresh, repo
	}

	t.Run("Given a logout with both tokens, When refreshing afterwards, Then the refresh token is rejected", func(t *testing.T) {
		svc, _, access, refresh, _ := login(t)

		assert.NoError(t, svc.Logout(context.Background(), access, refresh))

		_, _, _, err := svc.RefreshToken(context.Background(), refresh)
		assert.Error(t, err)
	})

	t.Run("Given a password change, When refreshing with an old refresh token, Then it is rejected", func(t *testing.T) {
		svc, _, _, refresh, repo := login(t)
		repo.On("UpdatePassword", mock.Anything, "u1", mock.Anything).Return(nil)
		time.Sleep(1100 * time.Millisecond) // iat has one-second resolution

		assert.NoError(t, svc.ChangePassword(context.Background(), "u1", "password123", "newpassword456"))

		_, _, _, err := svc.RefreshToken(context.Background(), refresh)
		assert.Error(t, err, "old refresh tokens must not survive a password change")
	})

	t.Run("Given account deletion, When using an old access token with the blacklist, Then it is revoked", func(t *testing.T) {
		svc, bl, access, _, repo := login(t)
		repo.On("SoftDelete", mock.Anything, "u1").Return(nil)
		time.Sleep(1100 * time.Millisecond)

		assert.NoError(t, svc.DeleteAccount(context.Background(), "u1"))

		manager := tokens.NewTokenManager("test-secret")
		claims, err := manager.ParseToken(access)
		assert.NoError(t, err)
		revoked, err := bl.IsRevoked(context.Background(), "u1", access, claims.IssuedAtTime())
		assert.NoError(t, err)
		assert.True(t, revoked)
	})
}
