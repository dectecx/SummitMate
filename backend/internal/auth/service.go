// Package auth implements registration, email verification, login and token rotation.
package auth

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/mail"
	"summitmate/internal/platform/ratelimit"
	"summitmate/internal/store"
)

const (
	maxVerifyAttempts = 5
	// refreshReuseGrace tolerates a client retrying a refresh whose response was lost.
	refreshReuseGrace = 10 * time.Second
)

// Options configures a Service.
type Options struct {
	RefreshTTL time.Duration
	CodeTTL    time.Duration
	BcryptCost int
	// FixedCode, when set, replaces the random verification code. Development only.
	FixedCode string
	// Limiters. nil disables the corresponding limit.
	LoginFailures ratelimit.Limiter // key: email; counts failed logins
	Resend        ratelimit.Limiter // key: email; counts code sends
	Now           func() time.Time  // defaults to time.Now
}

// Service holds the auth business rules.
type Service struct {
	repo   Repository
	tokens *TokenManager
	mailer mail.Mailer
	opt    Options
	// dummyHash is compared against when the user does not exist, so that
	// "unknown email" and "wrong password" take the same time.
	dummyHash string
}

func NewService(repo Repository, tokens *TokenManager, mailer mail.Mailer, opt Options) (*Service, error) {
	if opt.Now == nil {
		opt.Now = time.Now
	}
	if opt.BcryptCost == 0 {
		opt.BcryptCost = 12
	}
	dummy, err := hashPassword("dummy-password-1", opt.BcryptCost)
	if err != nil {
		return nil, err
	}
	return &Service{repo: repo, tokens: tokens, mailer: mailer, opt: opt, dummyHash: dummy}, nil
}

// TokenPair is a freshly issued access and refresh token.
type TokenPair struct {
	AccessToken  string
	RefreshToken string
	ExpiresIn    time.Duration
}

// Result is returned after a successful sign-in.
type Result struct {
	User   store.User
	Tokens TokenPair
}

type RegisterInput struct {
	Email       string
	Password    string
	DisplayName string
	Avatar      string
}

// Register creates an unverified account and sends a verification code. No tokens are issued.
func (s *Service) Register(ctx context.Context, in RegisterInput) (string, error) {
	email, err := normalizeEmail(in.Email)
	if err != nil {
		return "", err
	}
	if err := validatePassword(in.Password); err != nil {
		return "", err
	}
	name := strings.TrimSpace(in.DisplayName)
	if name == "" || len([]rune(name)) > 100 {
		return "", apperror.ErrBadRequest.WithParam("display_name")
	}
	avatar := in.Avatar
	if avatar == "" {
		avatar = "🐻"
	}
	hash, err := hashPassword(in.Password, s.opt.BcryptCost)
	if err != nil {
		return "", err
	}
	var user store.User
	err = s.repo.InTx(ctx, func(r Repository) error {
		existing, err := r.GetUserByEmail(ctx, email)
		switch {
		case err == nil && existing.IsVerified:
			return apperror.ErrEmailExists
		case err == nil:
			// Unverified account: let the person re-register to fix a typo in the password or name.
			user, err = r.UpdateUserProfile(ctx, store.UpdateUserProfileParams{
				ID: existing.ID, DisplayName: pgtype.Text{String: name, Valid: true}, Avatar: pgtype.Text{String: avatar, Valid: true},
			})
			if err != nil {
				return err
			}
			return r.UpdateUserPassword(ctx, store.UpdateUserPasswordParams{ID: existing.ID, PasswordHash: hash})
		case !isNotFound(err):
			return err
		}
		user, err = r.CreateUser(ctx, store.CreateUserParams{Email: email, PasswordHash: hash, DisplayName: name, Avatar: avatar})
		return err
	})
	if err != nil {
		return "", err
	}
	if err := s.sendCode(ctx, user); err != nil {
		return "", err
	}
	return email, nil
}

func (s *Service) sendCode(ctx context.Context, u store.User) error {
	code, err := s.nextCode()
	if err != nil {
		return err
	}
	if err := s.repo.UpsertVerification(ctx, store.UpsertVerificationParams{
		UserID: u.ID, CodeHash: hashCode(u.ID.String(), code), ExpiresAt: s.opt.Now().Add(s.opt.CodeTTL),
	}); err != nil {
		return err
	}
	return s.mailer.SendVerificationCode(ctx, u.Email, code)
}

// ResendVerification sends a new code. It succeeds silently for unknown or already
// verified emails so that it cannot be used to discover which emails are registered.
func (s *Service) ResendVerification(ctx context.Context, rawEmail string) error {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}
	if s.opt.Resend != nil {
		if !s.opt.Resend.Allow(email) {
			return apperror.ErrTooManyRequests
		}
		s.opt.Resend.Record(email)
	}
	u, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil {
		if isNotFound(err) {
			return nil
		}
		return err
	}
	if u.IsVerified || !u.IsActive {
		return nil
	}
	return s.sendCode(ctx, u)
}

// VerifyEmail checks the code, marks the account verified and signs the user in.
func (s *Service) VerifyEmail(ctx context.Context, rawEmail, code string) (Result, error) {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return Result{}, err
	}
	u, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil {
		if isNotFound(err) {
			return Result{}, apperror.ErrInvalidCode
		}
		return Result{}, err
	}
	if !u.IsActive {
		return Result{}, apperror.ErrAccountDisabled
	}
	v, err := s.repo.GetVerification(ctx, u.ID)
	if err != nil {
		if isNotFound(err) {
			return Result{}, apperror.ErrCodeExpired
		}
		return Result{}, err
	}
	if s.opt.Now().After(v.ExpiresAt) {
		return Result{}, apperror.ErrCodeExpired
	}
	if v.Attempts >= maxVerifyAttempts {
		return Result{}, apperror.ErrTooManyRequests
	}
	if !codesEqual(v.CodeHash, hashCode(u.ID.String(), code)) {
		if _, err := s.repo.IncrementVerificationAttempts(ctx, u.ID); err != nil {
			return Result{}, err
		}
		return Result{}, apperror.ErrInvalidCode
	}
	var res Result
	err = s.repo.InTx(ctx, func(r Repository) error {
		if err := r.MarkUserVerified(ctx, u.ID); err != nil {
			return err
		}
		if err := r.DeleteVerification(ctx, u.ID); err != nil {
			return err
		}
		u.IsVerified = true
		var err error
		res, err = s.issue(ctx, r, u)
		return err
	})
	return res, err
}

// Login verifies credentials. The password is checked before account state, so state
// is only revealed to someone who knows the password.
func (s *Service) Login(ctx context.Context, rawEmail, password string) (Result, error) {
	email := strings.ToLower(strings.TrimSpace(rawEmail))
	if s.opt.LoginFailures != nil && !s.opt.LoginFailures.Allow(email) {
		return Result{}, apperror.ErrTooManyRequests
	}
	u, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil && !isNotFound(err) {
		return Result{}, err
	}
	hash := s.dummyHash
	if err == nil {
		hash = u.PasswordHash
	}
	ok := checkPassword(password, hash) && err == nil
	if !ok {
		if s.opt.LoginFailures != nil {
			s.opt.LoginFailures.Record(email)
		}
		return Result{}, apperror.ErrInvalidCredentials
	}
	if !u.IsActive {
		return Result{}, apperror.ErrAccountDisabled
	}
	if !u.IsVerified {
		return Result{}, apperror.ErrEmailNotVerified
	}
	if s.opt.LoginFailures != nil {
		s.opt.LoginFailures.Reset(email)
	}
	var res Result
	err = s.repo.InTx(ctx, func(r Repository) error {
		if err := r.TouchUserLogin(ctx, u.ID); err != nil {
			return err
		}
		var err error
		res, err = s.issue(ctx, r, u)
		return err
	})
	return res, err
}

func (s *Service) issue(ctx context.Context, r Repository, u store.User) (Result, error) {
	pair, _, err := s.newPair(ctx, r, u.ID)
	return Result{User: u, Tokens: pair}, err
}

func (s *Service) newPair(ctx context.Context, r Repository, userID uuid.UUID) (TokenPair, store.RefreshToken, error) {
	access, err := s.tokens.NewAccessToken(userID.String())
	if err != nil {
		return TokenPair{}, store.RefreshToken{}, err
	}
	raw, hash, err := NewRefreshToken()
	if err != nil {
		return TokenPair{}, store.RefreshToken{}, err
	}
	row, err := r.CreateRefreshToken(ctx, store.CreateRefreshTokenParams{
		UserID: userID, TokenHash: hash, ExpiresAt: s.opt.Now().Add(s.opt.RefreshTTL),
	})
	if err != nil {
		return TokenPair{}, store.RefreshToken{}, err
	}
	return TokenPair{AccessToken: access, RefreshToken: raw, ExpiresIn: s.tokens.AccessTTL()}, row, nil
}

// Refresh rotates a refresh token. Presenting an already-revoked token is treated as
// theft: every refresh token of that user is revoked.
func (s *Service) Refresh(ctx context.Context, token string) (TokenPair, error) {
	var out TokenPair
	var reuse bool
	err := s.repo.InTx(ctx, func(r Repository) error {
		old, err := r.GetRefreshTokenByHash(ctx, HashToken(token))
		if err != nil {
			if isNotFound(err) {
				return apperror.ErrInvalidRefreshToken
			}
			return err
		}
		if old.RevokedAt != nil {
			switch {
			case old.ReplacedBy == nil:
				// Revoked by logout or password change: just invalid, not theft.
				return apperror.ErrInvalidRefreshToken
			case s.opt.Now().Sub(*old.RevokedAt) <= refreshReuseGrace:
				// The client probably never received the response to its refresh and is retrying.
			default:
				// A rotated token presented again later: assume it leaked and end every session.
				reuse = true
				return r.RevokeAllRefreshTokens(ctx, old.UserID)
			}
		}
		if s.opt.Now().After(old.ExpiresAt) {
			return apperror.ErrInvalidRefreshToken
		}
		u, err := r.GetUserByID(ctx, old.UserID)
		if err != nil {
			return err
		}
		if !u.IsActive {
			return apperror.ErrInvalidRefreshToken
		}
		pair, row, err := s.newPair(ctx, r, u.ID)
		if err != nil {
			return err
		}
		out = pair
		if old.RevokedAt != nil {
			return nil // retry inside the grace window: the old token is already revoked
		}
		return r.RevokeRefreshToken(ctx, store.RevokeRefreshTokenParams{ID: old.ID, ReplacedBy: &row.ID})
	})
	if err != nil {
		return TokenPair{}, err
	}
	if reuse {
		return TokenPair{}, apperror.ErrInvalidRefreshToken
	}
	return out, nil
}

// Logout revokes one refresh token. Unknown tokens are ignored.
func (s *Service) Logout(ctx context.Context, token string) error {
	rt, err := s.repo.GetRefreshTokenByHash(ctx, HashToken(token))
	if err != nil {
		if isNotFound(err) {
			return nil
		}
		return err
	}
	return s.repo.RevokeRefreshToken(ctx, store.RevokeRefreshTokenParams{ID: rt.ID})
}

// Me returns the user for an access-token subject.
func (s *Service) Me(ctx context.Context, userID uuid.UUID) (store.User, error) {
	u, err := s.repo.GetUserByID(ctx, userID)
	if err != nil {
		if isNotFound(err) {
			return store.User{}, apperror.ErrUnauthorized
		}
		return store.User{}, err
	}
	if !u.IsActive {
		return store.User{}, apperror.ErrAccountDisabled
	}
	return u, nil
}

// UpdateProfile changes display name and/or avatar; nil leaves a field unchanged.
func (s *Service) UpdateProfile(ctx context.Context, userID uuid.UUID, displayName, avatar *string) (store.User, error) {
	p := store.UpdateUserProfileParams{ID: userID}
	if displayName != nil {
		n := strings.TrimSpace(*displayName)
		if n == "" || len([]rune(n)) > 100 {
			return store.User{}, apperror.ErrBadRequest.WithParam("display_name")
		}
		p.DisplayName = pgtype.Text{String: n, Valid: true}
	}
	if avatar != nil {
		if *avatar == "" || len(*avatar) > 255 {
			return store.User{}, apperror.ErrBadRequest.WithParam("avatar")
		}
		p.Avatar = pgtype.Text{String: *avatar, Valid: true}
	}
	if _, err := s.Me(ctx, userID); err != nil {
		return store.User{}, err
	}
	return s.repo.UpdateUserProfile(ctx, p)
}

// ChangePassword verifies the current password, sets the new one and revokes all sessions.
func (s *Service) ChangePassword(ctx context.Context, userID uuid.UUID, current, next string) error {
	u, err := s.Me(ctx, userID)
	if err != nil {
		return err
	}
	if !checkPassword(current, u.PasswordHash) {
		return apperror.ErrPasswordMismatch
	}
	if err := validatePassword(next); err != nil {
		return err.(*apperror.Error).WithParam("new_password")
	}
	hash, err := hashPassword(next, s.opt.BcryptCost)
	if err != nil {
		return err
	}
	return s.repo.InTx(ctx, func(r Repository) error {
		if err := r.UpdateUserPassword(ctx, store.UpdateUserPasswordParams{ID: userID, PasswordHash: hash}); err != nil {
			return err
		}
		return r.RevokeAllRefreshTokens(ctx, userID)
	})
}

// DeleteAccount deactivates the account and revokes every refresh token.
func (s *Service) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	return s.repo.InTx(ctx, func(r Repository) error {
		if err := r.DeactivateUser(ctx, userID); err != nil {
			return err
		}
		return r.RevokeAllRefreshTokens(ctx, userID)
	})
}

// FindByEmail returns the verified, active user with exactly this email (for inviting members).
func (s *Service) FindByEmail(ctx context.Context, rawEmail string) ([]store.User, error) {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return nil, err
	}
	u, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil {
		if isNotFound(err) {
			return []store.User{}, nil
		}
		return nil, err
	}
	if !u.IsVerified || !u.IsActive {
		return []store.User{}, nil
	}
	return []store.User{u}, nil
}

// nextCode returns the verification code to send: the fixed development code
// when configured, otherwise a random one.
func (s *Service) nextCode() (string, error) {
	if s.opt.FixedCode != "" {
		return s.opt.FixedCode, nil
	}
	return newVerificationCode()
}
