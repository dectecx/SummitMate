package auth

import (
	"context"
	"errors"
	"log/slog"
	"regexp"
	"time"
	"unicode"

	"summitmate/internal/apperror"
	"summitmate/internal/auth/tokens"
	"summitmate/internal/flag"
	"summitmate/pkg/cache"
	"summitmate/pkg/email"
)

// AuthService 定義認證相關的業務邏輯介面。
type AuthService interface {
	Register(ctx context.Context, email, password, displayName string, avatar *string) (*User, string, error)
	Login(ctx context.Context, email, password string) (*User, string, error)
	GetUserByID(ctx context.Context, id string) (*User, error)
	UpdateProfile(ctx context.Context, id string, displayName, avatar *string) (*User, error)
	DeleteAccount(ctx context.Context, id string) error
	RefreshToken(ctx context.Context, oldToken string) (*User, string, error)
	VerifyEmail(ctx context.Context, email, code string) error
	ResendVerificationCode(ctx context.Context, email string) error
	SearchUserByEmail(ctx context.Context, email string) (*User, error)
}

type authService struct {
	logger       *slog.Logger
	userRepo     UserRepository
	tokenManager *tokens.TokenManager
	emailService *email.EmailService
	authCache    cache.Cache[string]
	flagService  flag.Service
	jwtSecret    []byte
}

func NewAuthService(
	logger *slog.Logger,
	userRepo UserRepository,
	tokenManager *tokens.TokenManager,
	emailService *email.EmailService,
	authCache cache.Cache[string],
	flagService flag.Service,
	jwtSecret string,
) AuthService {
	return &authService{
		logger:       logger.With("component", "auth"),
		userRepo:     userRepo,
		tokenManager: tokenManager,
		emailService: emailService,
		authCache:    authCache,
		flagService:  flagService,
		jwtSecret:    []byte(jwtSecret),
	}
}

// Register 處理使用者註冊流程：
//  1. 檢查 Email 是否已被使用
//  2. 將密碼以 bcrypt 雜湊
//  3. 寫入資料庫
//  4. 簽發 JWT Token
//
// 回傳新建的 User、JWT Token、或錯誤。
func (svc *authService) Register(ctx context.Context, emailAddr, password, displayName string, avatar *string) (*User, string, error) {
	// 驗證 Email 格式
	if !isValidEmail(emailAddr) {
		return nil, "", apperror.ErrInvalidEmail
	}

	// 驗證密碼強度
	if err := validatePasswordStrength(password); err != nil {
		return nil, "", err
	}

	// 檢查 Email 是否已存在
	_, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err == nil {
		svc.logger.WarnContext(ctx, "註冊失敗: Email 已存在", "email", emailAddr)
		return nil, "", apperror.ErrEmailExists
	}
	if !errors.Is(err, ErrNotFound) {
		svc.logger.ErrorContext(ctx, "註冊時資料庫查詢失敗", "email", emailAddr, "error", err)
		return nil, "", err // 資料庫錯誤
	}

	// 產生驗證碼
	code, err := GenerateVerificationCode()
	if err != nil {
		return nil, "", err
	}

	// 存入快取 (10 分鐘)
	if err := svc.authCache.Set(ctx, authVerificationKey(emailAddr), code, 10*time.Minute); err != nil {
		svc.logger.ErrorContext(ctx, "快取寫入失敗", "email", emailAddr, "error", err)
		return nil, "", err
	}

	// 雜湊密碼
	hash, err := HashPassword(password)
	if err != nil {
		return nil, "", err
	}

	// 寫入資料庫
	newUser := &User{
		Email:        emailAddr,
		PasswordHash: hash,
		DisplayName:  displayName,
		IsVerified:   false,
	}
	if avatar != nil && *avatar != "" {
		newUser.Avatar = *avatar
	}
	createdUser, err := svc.userRepo.Create(ctx, newUser)
	if err != nil {
		svc.logger.ErrorContext(ctx, "註冊時寫入資料庫失敗", "email", emailAddr, "error", err)
		return nil, "", err
	}

	svc.logger.InfoContext(ctx, "使用者註冊成功", "user_id", createdUser.ID, "email", emailAddr)

	// 非同步發送驗證信 (檢查旗標)
	if svc.emailService != nil && svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		go func() {
			if err := svc.emailService.SendVerificationCode(createdUser.Email, code, 10); err != nil {
				svc.logger.Error("發送驗證信失敗", "user_id", createdUser.ID, "error", err)
			}
		}()
	} else if !svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		svc.logger.Info("發送驗證信已停用 (旗標控制)", "email", createdUser.Email, "code", code)
	}

	// 簽發 JWT Token (有效期 24 小時)
	token, err := svc.tokenManager.GenerateToken(createdUser.ID, createdUser.Email, 24*time.Hour)
	if err != nil {
		return nil, "", err
	}

	return createdUser, token, nil
}

// Login 處理使用者登入流程：
//  1. 以 Email 查詢使用者
//  2. 驗證密碼
//  3. 簽發 JWT Token
//
// 回傳 User、JWT Token、或錯誤。
func (svc *authService) Login(ctx context.Context, email, password string) (*User, string, error) {
	// 查詢使用者
	user, err := svc.userRepo.GetByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			svc.logger.WarnContext(ctx, "登入失敗: 找不到使用者", "email", email)
			return nil, "", apperror.ErrInvalidCredentials
		}
		svc.logger.ErrorContext(ctx, "登入時資料庫查詢失敗", "email", email, "error", err)
		return nil, "", err
	}

	// 驗證密碼
	if !CheckPasswordHash(password, user.PasswordHash) {
		svc.logger.WarnContext(ctx, "登入失敗: 密碼不正確", "user_id", user.ID, "email", email)
		return nil, "", apperror.ErrInvalidCredentials
	}

	svc.logger.InfoContext(ctx, "使用者登入成功", "user_id", user.ID, "email", email)

	// 簽發 JWT Token (有效期 24 小時)
	token, err := svc.tokenManager.GenerateToken(user.ID, user.Email, 24*time.Hour)
	if err != nil {
		return nil, "", err
	}

	return user, token, nil
}

// GetUserByID 依 ID 取得使用者資料。
func (svc *authService) GetUserByID(ctx context.Context, id string) (*User, error) {
	return svc.userRepo.GetByID(ctx, id)
}

// UpdateProfile 更新使用者的個人資料 (display_name, avatar)。
func (svc *authService) UpdateProfile(ctx context.Context, userID string, displayName, avatar *string) (*User, error) {
	user, err := svc.userRepo.Update(ctx, userID, displayName, avatar)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, apperror.ErrUserNotFound
		}
		return nil, err
	}
	return user, nil
}

// DeleteAccount 軟刪除使用者帳號 (設定 is_active = false)。
func (svc *authService) DeleteAccount(ctx context.Context, userID string) error {
	err := svc.userRepo.SoftDelete(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return apperror.ErrUserNotFound
		}
		return err
	}
	return nil
}

// RefreshToken 解析現有 Token 並簽發新的 JWT Token。
// 即使 Token 已過期，只要格式正確且簽名有效，仍會簽發新 Token。
func (svc *authService) RefreshToken(ctx context.Context, tokenString string) (*User, string, error) {
	claims, err := svc.tokenManager.ParseToken(tokenString)
	if err != nil {
		return nil, "", apperror.ErrTokenExpired
	}

	user, err := svc.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, "", apperror.ErrUserNotFound
		}
		return nil, "", err
	}

	if !user.IsActive {
		return nil, "", apperror.ErrUnauthorized.WithMessage("帳號已停用")
	}

	newToken, err := svc.tokenManager.GenerateToken(user.ID, user.Email, 24*time.Hour)
	if err != nil {
		return nil, "", err
	}

	return user, newToken, nil
}

// VerifyEmail 驗證使用者的 Email。
func (svc *authService) VerifyEmail(ctx context.Context, emailAddr, code string) error {
	user, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return apperror.ErrInvalidVerificationCode
		}
		return err
	}

	if user.IsVerified {
		return nil // 已經驗證過了
	}

	// 檢查旗標是否允許跳過驗證碼校驗
	if svc.flagService.IsEnabled(ctx, flag.SkipVerificationCode) {
		svc.logger.Info("驗證碼校驗跳過 (旗標控制)", "email", emailAddr, "input_code", code)
		if err := svc.userRepo.SetVerified(ctx, user.ID); err != nil {
			return err
		}
		return nil
	}

	// 從快取取得驗證碼
	cachedCode, err := svc.authCache.Get(ctx, authVerificationKey(emailAddr))
	if err != nil {
		if errors.Is(err, cache.ErrKeyNotFound) {
			return apperror.ErrVerificationCodeExpired
		}
		return err
	}

	if cachedCode != code {
		return apperror.ErrInvalidVerificationCode
	}

	// 驗證成功，更新資料庫並刪除快取
	if err := svc.userRepo.SetVerified(ctx, user.ID); err != nil {
		return err
	}
	_ = svc.authCache.Delete(ctx, authVerificationKey(emailAddr))

	return nil
}

// ResendVerificationCode 重發驗證碼。
func (svc *authService) ResendVerificationCode(ctx context.Context, emailAddr string) error {
	user, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			svc.logger.WarnContext(ctx, "重發驗證碼失敗: 找不到使用者 (基於安全隱藏)", "email", emailAddr)
			return nil // 基於安全性，隱藏使用者是否存在
		}
		return err
	}

	if user.IsVerified {
		return nil
	}

	code, err := GenerateVerificationCode()
	if err != nil {
		return err
	}

	// 更新快取
	if err := svc.authCache.Set(ctx, authVerificationKey(emailAddr), code, 10*time.Minute); err != nil {
		return err
	}

	if svc.emailService != nil && svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		go func() {
			if err := svc.emailService.SendVerificationCode(user.Email, code, 10); err != nil {
				svc.logger.Error("重發驗證信失敗", "user_id", user.ID, "error", err)
			}
		}()
	} else if !svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		svc.logger.Info("重發驗證信已停用 (旗標控制)", "email", user.Email, "code", code)
	}

	return nil
}

// SearchUserByEmail 透過 Email 搜尋使用者。
func (svc *authService) SearchUserByEmail(ctx context.Context, emailAddr string) (*User, error) {
	return svc.userRepo.GetByEmail(ctx, emailAddr)
}

// --- Validation Helpers ---

func isValidEmail(email string) bool {
	// 簡單的 Email 正則表達式
	pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
	match, _ := regexp.MatchString(pattern, email)
	return match
}

func validatePasswordStrength(password string) error {
	if len(password) < 8 {
		return apperror.ErrPasswordTooShort
	}

	var hasLetter, hasNumber bool
	for _, r := range password {
		if unicode.IsLetter(r) {
			hasLetter = true
		} else if unicode.IsNumber(r) {
			hasNumber = true
		}
	}

	if !hasLetter || !hasNumber {
		return apperror.ErrPasswordTooWeak
	}

	return nil
}
