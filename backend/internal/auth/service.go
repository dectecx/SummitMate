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
	// Registration & Verification
	Register(ctx context.Context, email, password, displayName string, avatar *string) (*User, string, string, error)
	VerifyEmail(ctx context.Context, emailAddr, code string) error
	ResendVerificationCode(ctx context.Context, emailAddr string) error

	// Session
	Login(ctx context.Context, email, password string) (*User, string, string, error)
	Logout(ctx context.Context, token string) error
	RefreshToken(ctx context.Context, tokenString string) (*User, string, string, error)

	// Credentials
	ChangePassword(ctx context.Context, userID string, oldPassword, newPassword string, currentToken string) error

	// User Profile
	GetUserByID(ctx context.Context, id string) (*User, error)
	SearchUserByEmail(ctx context.Context, emailAddr string) (*User, error)
	UpdateProfile(ctx context.Context, userID string, displayName, avatar *string) (*User, error)
	DeleteAccount(ctx context.Context, userID string) error
}

type authService struct {
	logger       *slog.Logger
	userRepo     UserRepository
	tokenManager *tokens.TokenManager
	emailService *email.EmailService
	authCache    cache.Cache[string]
	flagService  flag.FlagService
	jwtSecret    []byte
}

func NewAuthService(
	logger *slog.Logger,
	userRepo UserRepository,
	tokenManager *tokens.TokenManager,
	emailService *email.EmailService,
	authCache cache.Cache[string],
	flagService flag.FlagService,
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
func (svc *authService) Register(ctx context.Context, emailAddr, password, displayName string, avatar *string) (*User, string, string, error) {
	// 驗證 Email 格式
	if !isValidEmail(emailAddr) {
		return nil, "", "", apperror.ErrInvalidEmail
	}

	// 驗證密碼強度
	if err := validatePasswordStrength(password); err != nil {
		return nil, "", "", err
	}

	// 檢查 Email 是否已存在
	_, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err == nil {
		svc.logger.WarnContext(ctx, "註冊失敗: Email 已存在", "email", emailAddr)
		return nil, "", "", apperror.ErrEmailExists
	}
	if !errors.Is(err, ErrNotFound) {
		svc.logger.ErrorContext(ctx, "註冊時資料庫查詢失敗", "email", emailAddr, "error", err)
		return nil, "", "", err // 資料庫錯誤
	}

	// 產生驗證碼
	code, err := GenerateVerificationCode()
	if err != nil {
		return nil, "", "", err
	}

	// 存入快取 (10 分鐘)
	if err := svc.authCache.Set(ctx, authVerificationKey(emailAddr), code, 10*time.Minute); err != nil {
		svc.logger.ErrorContext(ctx, "快取寫入失敗", "email", emailAddr, "error", err)
		return nil, "", "", err
	}

	// 雜湊密碼
	hash, err := HashPassword(password)
	if err != nil {
		return nil, "", "", err
	}

	// 取得預設 MEMBER 角色
	roleID, err := svc.userRepo.GetRoleIDByCode(ctx, "MEMBER")
	if err != nil {
		svc.logger.ErrorContext(ctx, "無法取得預設角色", "error", err)
		return nil, "", "", err
	}

	// 寫入資料庫
	newUser := &User{
		Email:        emailAddr,
		PasswordHash: hash,
		DisplayName:  displayName,
		RoleID:       &roleID,
		IsVerified:   false,
	}
	if avatar != nil && *avatar != "" {
		newUser.Avatar = *avatar
	}
	createdUser, err := svc.userRepo.Create(ctx, newUser)
	if err != nil {
		svc.logger.ErrorContext(ctx, "註冊時寫入資料庫失敗", "email", emailAddr, "error", err)
		return nil, "", "", err
	}

	svc.logger.InfoContext(ctx, "使用者註冊成功", "user_id", createdUser.ID, "email", emailAddr)

	// 非同步發送驗證信 (檢查旗標)
	if svc.emailService != nil && svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		go func() {
			mailCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()
			if err := svc.emailService.SendVerificationCode(mailCtx, createdUser.Email, code, 10); err != nil {
				svc.logger.Error("發送驗證信失敗", "user_id", createdUser.ID, "error", err)
			}
		}()
	} else if !svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		svc.logger.Info("發送驗證信已停用 (旗標控制)", "email", createdUser.Email, "code", code)
	}

	// 簽發 JWT Token (Access: 1 小時, Refresh: 14 天)
	accessToken, err := svc.tokenManager.GenerateToken(createdUser.ID, createdUser.Email, "access", 1*time.Hour)
	if err != nil {
		return nil, "", "", err
	}
	refreshToken, err := svc.tokenManager.GenerateToken(createdUser.ID, createdUser.Email, "refresh", 14*24*time.Hour)
	if err != nil {
		return nil, "", "", err
	}

	return createdUser, accessToken, refreshToken, nil
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
			mailCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()
			if err := svc.emailService.SendVerificationCode(mailCtx, user.Email, code, 10); err != nil {
				svc.logger.Error("重發驗證信失敗", "user_id", user.ID, "error", err)
			}
		}()
	} else if !svc.flagService.IsEnabled(ctx, flag.EnableEmailSending) {
		svc.logger.Info("重發驗證信已停用 (旗標控制)", "email", user.Email, "code", code)
	}

	return nil
}

// Login 處理使用者登入流程：
//  1. 以 Email 查詢使用者
//  2. 驗證密碼
//  3. 簽發 JWT Token
//
// 回傳 User、JWT Token、或錯誤。
func (svc *authService) Login(ctx context.Context, email, password string) (*User, string, string, error) {
	// 查詢使用者
	user, err := svc.userRepo.GetByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			svc.logger.WarnContext(ctx, "登入失敗: 找不到使用者", "email", email)
			return nil, "", "", apperror.ErrInvalidCredentials
		}
		svc.logger.ErrorContext(ctx, "登入時資料庫查詢失敗", "email", email, "error", err)
		return nil, "", "", err
	}

	// 驗證密碼
	if !CheckPasswordHash(password, user.PasswordHash) {
		svc.logger.WarnContext(ctx, "登入失敗: 密碼不正確", "user_id", user.ID, "email", email)
		return nil, "", "", apperror.ErrInvalidCredentials
	}

	svc.logger.InfoContext(ctx, "使用者登入成功", "user_id", user.ID, "email", email)

	// 簽發 JWT Token (Access: 1 小時, Refresh: 14 天)
	accessToken, err := svc.tokenManager.GenerateToken(user.ID, user.Email, "access", 1*time.Hour)
	if err != nil {
		return nil, "", "", err
	}
	refreshToken, err := svc.tokenManager.GenerateToken(user.ID, user.Email, "refresh", 14*24*time.Hour)
	if err != nil {
		return nil, "", "", err
	}

	return user, accessToken, refreshToken, nil
}

// Logout 註銷指定 Token，將其加入黑名單。
func (svc *authService) Logout(ctx context.Context, tokenStr string) error {
	claims, err := svc.tokenManager.ParseToken(tokenStr)
	if err != nil {
		// Token 已經無效或過期，不需要再加入黑名單
		return nil
	}

	// 計算 Token 剩餘存活時間 (TTL)
	expiration := claims.ExpiresAt.Time
	ttl := time.Until(expiration)
	if ttl <= 0 {
		return nil
	}

	// 存入黑名單，值可以使用 "1"
	if err := svc.authCache.Set(ctx, authBlacklistKey(tokenStr), "1", ttl); err != nil {
		svc.logger.ErrorContext(ctx, "寫入 Token 黑名單失敗", "error", err)
		return err
	}

	return nil
}

// RefreshToken 解析現有的 Refresh Token 並簽發新的 JWT Tokens。
func (svc *authService) RefreshToken(ctx context.Context, tokenString string) (*User, string, string, error) {
	claims, err := svc.tokenManager.ParseToken(tokenString)
	if err != nil {
		return nil, "", "", apperror.ErrTokenExpired
	}

	if claims.TokenType != "refresh" {
		return nil, "", "", apperror.ErrUnauthorized.WithMessage("無效的 Token 類型")
	}

	user, err := svc.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, "", "", apperror.ErrUserNotFound
		}
		return nil, "", "", err
	}

	if !user.IsActive {
		return nil, "", "", apperror.ErrUnauthorized.WithMessage("帳號已停用")
	}

	newAccessToken, err := svc.tokenManager.GenerateToken(user.ID, user.Email, "access", 1*time.Hour)
	if err != nil {
		return nil, "", "", err
	}
	newRefreshToken, err := svc.tokenManager.GenerateToken(user.ID, user.Email, "refresh", 14*24*time.Hour)
	if err != nil {
		return nil, "", "", err
	}

	return user, newAccessToken, newRefreshToken, nil
}

// ChangePassword 修改使用者密碼，並將當前使用的 Token 註銷。
func (svc *authService) ChangePassword(ctx context.Context, userID string, oldPassword, newPassword string, currentToken string) error {
	// 驗證密碼強度
	if err := validatePasswordStrength(newPassword); err != nil {
		return err
	}

	// 取得使用者
	user, err := svc.userRepo.GetByID(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return apperror.ErrUserNotFound
		}
		return err
	}

	// 驗證舊密碼
	if !CheckPasswordHash(oldPassword, user.PasswordHash) {
		return apperror.ErrUnauthorized.WithMessage("舊密碼不正確")
	}

	// 雜湊新密碼
	newHash, err := HashPassword(newPassword)
	if err != nil {
		return err
	}

	// 更新資料庫
	if err := svc.userRepo.UpdatePassword(ctx, userID, newHash); err != nil {
		return err
	}

	// 註銷當前使用的 Token
	if currentToken != "" {
		if err := svc.Logout(ctx, currentToken); err != nil {
			svc.logger.WarnContext(ctx, "修改密碼後註銷當前 Token 失敗", "error", err)
		}
	}

	return nil
}

// GetUserByID 依 ID 取得使用者資料。
func (svc *authService) GetUserByID(ctx context.Context, id string) (*User, error) {
	return svc.userRepo.GetByID(ctx, id)
}

// SearchUserByEmail 透過 Email 搜尋使用者。
func (svc *authService) SearchUserByEmail(ctx context.Context, emailAddr string) (*User, error) {
	return svc.userRepo.GetByEmail(ctx, emailAddr)
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
