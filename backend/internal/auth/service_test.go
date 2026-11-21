package auth

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

type captureMailer struct{ codes map[string]string }

func (m *captureMailer) SendVerificationCode(_ context.Context, to, code string) error {
	m.codes[to] = code
	return nil
}

type env struct {
	svc    *Service
	repo   *fakeRepo
	mailer *captureMailer
	now    time.Time
}

func newEnv(t *testing.T) *env {
	t.Helper()
	e := &env{repo: newFakeRepo(), mailer: &captureMailer{codes: map[string]string{}}, now: time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)}
	tokens := NewTokenManager("test-secret-test-secret-test-secret-123", 15*time.Minute)
	tokens.now = func() time.Time { return e.now }
	svc, err := NewService(e.repo, tokens, e.mailer, Options{
		RefreshTTL: 14 * 24 * time.Hour, CodeTTL: 30 * time.Minute, BcryptCost: 4,
		LoginFailures: ratelimit.NewMemory(3, time.Minute),
		Resend:        ratelimit.NewMemory(1, time.Minute),
		Now:           func() time.Time { return e.now },
	})
	require.NoError(t, err)
	e.svc = svc
	e.repo.now = func() time.Time { return e.now }
	return e
}

func (e *env) registerVerified(t *testing.T, email string) Result {
	t.Helper()
	ctx := context.Background()
	_, err := e.svc.Register(ctx, RegisterInput{Email: email, Password: "Passw0rdX", DisplayName: "Tester"})
	require.NoError(t, err)
	res, err := e.svc.VerifyEmail(ctx, email, e.mailer.codes[email])
	require.NoError(t, err)
	return res
}

func requireCode(t *testing.T, err error, want *apperror.Error) {
	t.Helper()
	ae, ok := apperror.As(err)
	require.True(t, ok, "expected apperror, got %v", err)
	assert.Equal(t, want.Code, ae.Code)
}

func TestRegisterDoesNotIssueTokensAndVerifyDoes(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	email, err := e.svc.Register(ctx, RegisterInput{Email: " Me@Example.COM ", Password: "Passw0rdX", DisplayName: "Me"})
	require.NoError(t, err)
	assert.Equal(t, "me@example.com", email)
	assert.Empty(t, e.repo.tokens)

	_, err = e.svc.Login(ctx, "me@example.com", "Passw0rdX")
	requireCode(t, err, apperror.ErrEmailNotVerified)

	res, err := e.svc.VerifyEmail(ctx, "me@example.com", e.mailer.codes["me@example.com"])
	require.NoError(t, err)
	assert.True(t, res.User.IsVerified)
	assert.NotEmpty(t, res.Tokens.AccessToken)
	assert.NotEmpty(t, res.Tokens.RefreshToken)
}

func TestRegisterValidation(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	for name, tc := range map[string]struct {
		in   RegisterInput
		want *apperror.Error
	}{
		"bad email":  {RegisterInput{Email: "nope", Password: "Passw0rdX", DisplayName: "x"}, apperror.ErrInvalidEmail},
		"short":      {RegisterInput{Email: "a@b.co", Password: "Ab1", DisplayName: "x"}, apperror.ErrPasswordTooShort},
		"no digit":   {RegisterInput{Email: "a@b.co", Password: "abcdefgh", DisplayName: "x"}, apperror.ErrPasswordTooWeak},
		"too long":   {RegisterInput{Email: "a@b.co", Password: string(make([]byte, 73)), DisplayName: "x"}, apperror.ErrPasswordTooShort},
		"empty name": {RegisterInput{Email: "a@b.co", Password: "Passw0rdX", DisplayName: " "}, apperror.ErrBadRequest},
	} {
		t.Run(name, func(t *testing.T) {
			_, err := e.svc.Register(ctx, tc.in)
			requireCode(t, err, tc.want)
		})
	}
}

func TestRegisterExistingVerifiedEmailConflicts(t *testing.T) {
	e := newEnv(t)
	e.registerVerified(t, "a@b.co")
	_, err := e.svc.Register(context.Background(), RegisterInput{Email: "a@b.co", Password: "Passw0rdX", DisplayName: "x"})
	requireCode(t, err, apperror.ErrEmailExists)
}

func TestVerifyEmailWrongExpiredAndLocked(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	_, err := e.svc.Register(ctx, RegisterInput{Email: "a@b.co", Password: "Passw0rdX", DisplayName: "x"})
	require.NoError(t, err)
	good := e.mailer.codes["a@b.co"]
	bad := "000000"
	if good == bad {
		bad = "111111"
	}

	for i := 0; i < maxVerifyAttempts; i++ {
		_, err = e.svc.VerifyEmail(ctx, "a@b.co", bad)
		requireCode(t, err, apperror.ErrInvalidCode)
	}
	// Locked out even with the right code until a new one is requested.
	_, err = e.svc.VerifyEmail(ctx, "a@b.co", good)
	requireCode(t, err, apperror.ErrTooManyRequests)

	e.now = e.now.Add(31 * time.Minute)
	_, err = e.svc.VerifyEmail(ctx, "a@b.co", good)
	requireCode(t, err, apperror.ErrCodeExpired)
}

func TestResendIsSilentForUnknownAndRateLimited(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	require.NoError(t, e.svc.ResendVerification(ctx, "ghost@b.co"))
	assert.Empty(t, e.mailer.codes)

	_, err := e.svc.Register(ctx, RegisterInput{Email: "a@b.co", Password: "Passw0rdX", DisplayName: "x"})
	require.NoError(t, err)
	require.NoError(t, e.svc.ResendVerification(ctx, "a@b.co"))
	requireCode(t, e.svc.ResendVerification(ctx, "a@b.co"), apperror.ErrTooManyRequests)
}

func TestLoginWrongPasswordLimitAndUnknownUser(t *testing.T) {
	e := newEnv(t)
	e.registerVerified(t, "a@b.co")
	ctx := context.Background()

	_, err := e.svc.Login(ctx, "ghost@b.co", "Passw0rdX")
	requireCode(t, err, apperror.ErrInvalidCredentials)
	for i := 0; i < 2; i++ {
		_, err = e.svc.Login(ctx, "a@b.co", "wrong")
		requireCode(t, err, apperror.ErrInvalidCredentials)
	}
	// 3 failures recorded (ghost is a different key) -> the third wrong attempt is allowed, the next is blocked.
	_, err = e.svc.Login(ctx, "a@b.co", "wrong")
	requireCode(t, err, apperror.ErrInvalidCredentials)
	_, err = e.svc.Login(ctx, "a@b.co", "Passw0rdX")
	requireCode(t, err, apperror.ErrTooManyRequests)
}

func TestSuccessfulLoginResetsFailureCount(t *testing.T) {
	e := newEnv(t)
	e.registerVerified(t, "a@b.co")
	ctx := context.Background()
	for i := 0; i < 2; i++ {
		_, _ = e.svc.Login(ctx, "a@b.co", "wrong")
	}
	_, err := e.svc.Login(ctx, "a@b.co", "Passw0rdX")
	require.NoError(t, err)
	for i := 0; i < 3; i++ {
		_, err = e.svc.Login(ctx, "a@b.co", "wrong")
		requireCode(t, err, apperror.ErrInvalidCredentials)
	}
}

func TestDisabledAccountCannotLogInOrRefresh(t *testing.T) {
	e := newEnv(t)
	res := e.registerVerified(t, "a@b.co")
	ctx := context.Background()
	require.NoError(t, e.svc.DeleteAccount(ctx, res.User.ID))
	assert.Zero(t, e.repo.activeTokens(res.User.ID))

	_, err := e.svc.Login(ctx, "a@b.co", "Passw0rdX")
	requireCode(t, err, apperror.ErrAccountDisabled)
	_, err = e.svc.Refresh(ctx, res.Tokens.RefreshToken)
	requireCode(t, err, apperror.ErrInvalidRefreshToken)
}

func TestRefreshRotatesAndDetectsReuse(t *testing.T) {
	e := newEnv(t)
	res := e.registerVerified(t, "a@b.co")
	ctx := context.Background()

	second, err := e.svc.Refresh(ctx, res.Tokens.RefreshToken)
	require.NoError(t, err)
	assert.NotEqual(t, res.Tokens.RefreshToken, second.RefreshToken)
	assert.Equal(t, 1, e.repo.activeTokens(res.User.ID))

	// Retrying right away (lost response) is tolerated and does not end the session.
	retry, err := e.svc.Refresh(ctx, res.Tokens.RefreshToken)
	require.NoError(t, err)
	assert.Equal(t, 2, e.repo.activeTokens(res.User.ID))
	_ = retry

	// Presenting the rotated token long after the rotation is treated as theft: every session ends.
	e.now = e.now.Add(time.Minute)
	_, err = e.svc.Refresh(ctx, res.Tokens.RefreshToken)
	requireCode(t, err, apperror.ErrInvalidRefreshToken)
	assert.Zero(t, e.repo.activeTokens(res.User.ID))
	_, err = e.svc.Refresh(ctx, second.RefreshToken)
	requireCode(t, err, apperror.ErrInvalidRefreshToken)
}

func TestRefreshRejectsUnknownAndExpired(t *testing.T) {
	e := newEnv(t)
	res := e.registerVerified(t, "a@b.co")
	ctx := context.Background()
	_, err := e.svc.Refresh(ctx, "garbage")
	requireCode(t, err, apperror.ErrInvalidRefreshToken)
	e.now = e.now.Add(15 * 24 * time.Hour)
	_, err = e.svc.Refresh(ctx, res.Tokens.RefreshToken)
	requireCode(t, err, apperror.ErrInvalidRefreshToken)
}

func TestLogoutRevokesOnlyThatToken(t *testing.T) {
	e := newEnv(t)
	res := e.registerVerified(t, "a@b.co")
	ctx := context.Background()
	other, err := e.svc.Login(ctx, "a@b.co", "Passw0rdX")
	require.NoError(t, err)

	require.NoError(t, e.svc.Logout(ctx, res.Tokens.RefreshToken))
	require.NoError(t, e.svc.Logout(ctx, "unknown-token"))
	_, err = e.svc.Refresh(ctx, res.Tokens.RefreshToken)
	requireCode(t, err, apperror.ErrInvalidRefreshToken)
	_, err = e.svc.Refresh(ctx, other.Tokens.RefreshToken)
	require.NoError(t, err)
}

func TestChangePasswordRevokesSessions(t *testing.T) {
	e := newEnv(t)
	res := e.registerVerified(t, "a@b.co")
	ctx := context.Background()

	requireCode(t, e.svc.ChangePassword(ctx, res.User.ID, "wrong", "NewPassw0rd"), apperror.ErrPasswordMismatch)
	requireCode(t, e.svc.ChangePassword(ctx, res.User.ID, "Passw0rdX", "short"), apperror.ErrPasswordTooShort)
	require.NoError(t, e.svc.ChangePassword(ctx, res.User.ID, "Passw0rdX", "NewPassw0rd"))
	assert.Zero(t, e.repo.activeTokens(res.User.ID))

	_, err := e.svc.Login(ctx, "a@b.co", "Passw0rdX")
	requireCode(t, err, apperror.ErrInvalidCredentials)
	_, err = e.svc.Login(ctx, "a@b.co", "NewPassw0rd")
	require.NoError(t, err)
}

func TestFindByEmailOnlyReturnsVerifiedActiveUsers(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	_, err := e.svc.Register(ctx, RegisterInput{Email: "u@b.co", Password: "Passw0rdX", DisplayName: "x"})
	require.NoError(t, err)
	users, err := e.svc.FindByEmail(ctx, "u@b.co")
	require.NoError(t, err)
	assert.Empty(t, users, "unverified users are not discoverable")

	e.registerVerified(t, "v@b.co")
	users, err = e.svc.FindByEmail(ctx, "V@B.co")
	require.NoError(t, err)
	assert.Len(t, users, 1)
}

func TestAccessTokenRules(t *testing.T) {
	m := NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	m.now = func() time.Time { return now }

	tok, err := m.NewAccessToken("user-1")
	require.NoError(t, err)
	sub, err := m.ParseAccessToken(tok)
	require.NoError(t, err)
	assert.Equal(t, "user-1", sub)

	m.now = func() time.Time { return now.Add(2 * time.Minute) }
	_, err = m.ParseAccessToken(tok)
	assert.Error(t, err, "expired")
	m.now = func() time.Time { return now }

	none, err := jwt.NewWithClaims(jwt.SigningMethodNone, jwt.RegisteredClaims{
		Subject: "user-1", ExpiresAt: jwt.NewNumericDate(now.Add(time.Hour)),
	}).SignedString(jwt.UnsafeAllowNoneSignatureType)
	require.NoError(t, err)
	_, err = m.ParseAccessToken(none)
	assert.Error(t, err, "alg none")

	other := NewTokenManager("another-secret-another-secret-123456", time.Minute)
	other.now = m.now
	foreign, err := other.NewAccessToken("user-1")
	require.NoError(t, err)
	_, err = m.ParseAccessToken(foreign)
	assert.Error(t, err, "wrong key")

	noExp, err := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.RegisteredClaims{Subject: "user-1"}).SignedString(m.secret)
	require.NoError(t, err)
	_, err = m.ParseAccessToken(noExp)
	assert.Error(t, err, "missing exp")
}

func TestRefreshTokenHashing(t *testing.T) {
	a, ah, err := NewRefreshToken()
	require.NoError(t, err)
	b, _, err := NewRefreshToken()
	require.NoError(t, err)
	assert.NotEqual(t, a, b)
	assert.Equal(t, ah, HashToken(a))
	assert.NotContains(t, ah, a)
	assert.False(t, errors.Is(nil, ErrNotFound))
}
