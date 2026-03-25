package service

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	"summitmate/internal/model"
	"summitmate/internal/repository"
	"summitmate/pkg/email"
)

// AuthService 封裝認證相關的業務邏輯 (註冊、登入、取得使用者)。
type AuthService struct {
	logger       *slog.Logger
	userRepo     repository.UserRepository
	tokenManager *auth.TokenManager
	emailService *email.EmailService
	jwtSecret    []byte
}

func NewAuthService(logger *slog.Logger, userRepo repository.UserRepository, tokenManager *auth.TokenManager, emailService *email.EmailService, jwtSecret string) *AuthService {
	return &AuthService{
		logger:       logger.With("component", "auth"),
		userRepo:     userRepo,
		tokenManager: tokenManager,
		emailService: emailService,
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
func (svc *AuthService) Register(ctx context.Context, emailAddr, password, displayName string) (*model.User, string, error) {
	// 檢查 Email 是否已存在
	_, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err == nil {
		svc.logger.WarnContext(ctx, "註冊失敗: Email 已存在", "email", emailAddr)
		return nil, "", apperror.ErrEmailExists
	}
	if !errors.Is(err, repository.ErrNotFound) {
		svc.logger.ErrorContext(ctx, "註冊時資料庫查詢失敗", "email", emailAddr, "error", err)
		return nil, "", err // 資料庫錯誤
	}

	// 產生驗證碼
	code, err := auth.GenerateVerificationCode()
	if err != nil {
		return nil, "", err
	}
	expiry := time.Now().Add(10 * time.Minute)

	// 雜湊密碼
	hash, err := auth.HashPassword(password)
	if err != nil {
		return nil, "", err
	}

	// 寫入資料庫
	newUser := &model.User{
		Email:              emailAddr,
		PasswordHash:       hash,
		DisplayName:        displayName,
		VerificationCode:   &code,
		VerificationExpiry: &expiry,
		IsVerified:         false,
	}
	createdUser, err := svc.userRepo.Create(ctx, newUser)
	if err != nil {
		svc.logger.ErrorContext(ctx, "註冊時寫入資料庫失敗", "email", emailAddr, "error", err)
		return nil, "", err
	}

	svc.logger.InfoContext(ctx, "使用者註冊成功", "user_id", createdUser.ID, "email", emailAddr)

	// 非同步發送驗證信
	if svc.emailService != nil {
		go func() {
			if err := svc.emailService.SendVerificationCode(createdUser.Email, code, 10); err != nil {
				svc.logger.Error("發送驗證信失敗", "user_id", createdUser.ID, "error", err)
			}
		}()
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
func (svc *AuthService) Login(ctx context.Context, email, password string) (*model.User, string, error) {
	// 查詢使用者
	user, err := svc.userRepo.GetByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			svc.logger.WarnContext(ctx, "登入失敗: 找不到使用者", "email", email)
			return nil, "", apperror.ErrInvalidCredentials
		}
		svc.logger.ErrorContext(ctx, "登入時資料庫查詢失敗", "email", email, "error", err)
		return nil, "", err
	}

	// 驗證密碼
	if !auth.CheckPasswordHash(password, user.PasswordHash) {
		svc.logger.WarnContext(ctx, "登入失敗: 密碼不正確", "user_id", user.ID, "email", email)
		return nil, "", apperror.ErrInvalidCredentials
	}

	svc.logger.InfoContext(ctx, "使用者登入成功", "user_id", user.ID, "email", email)

	// 簽發 JWT Token (有效期 24 小時)
	token, err := svc.tokenManager.GenerateToken(user.ID, user.Email, 24*time.Hour)
	if err != nil {
		return nil, "", err
	}

	// TODO: 考慮非同步更新 last_login_at

	return user, token, nil
}

// GetUserByID 依 ID 取得使用者資料。
func (svc *AuthService) GetUserByID(ctx context.Context, id string) (*model.User, error) {
	return svc.userRepo.GetByID(ctx, id)
}

// UpdateProfile 更新使用者的個人資料 (display_name, avatar)。
func (svc *AuthService) UpdateProfile(ctx context.Context, userID string, displayName, avatar *string) (*model.User, error) {
	user, err := svc.userRepo.Update(ctx, userID, displayName, avatar)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, apperror.ErrUserNotFound
		}
		return nil, err
	}
	return user, nil
}

// DeleteAccount 軟刪除使用者帳號 (設定 is_active = false)。
func (svc *AuthService) DeleteAccount(ctx context.Context, userID string) error {
	err := svc.userRepo.SoftDelete(ctx, userID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return apperror.ErrUserNotFound
		}
		return err
	}
	return nil
}

// RefreshToken 解析現有 Token 並簽發新的 JWT Token。
// 即使 Token 已過期，只要格式正確且簽名有效，仍會簽發新 Token。
func (svc *AuthService) RefreshToken(ctx context.Context, tokenString string) (*model.User, string, error) {
	claims, err := svc.tokenManager.ParseToken(tokenString)
	if err != nil {
		return nil, "", apperror.ErrTokenExpired
	}

	user, err := svc.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
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
func (svc *AuthService) VerifyEmail(ctx context.Context, emailAddr, code string) error {
	user, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return apperror.ErrInvalidVerificationCode
		}
		return err
	}

	if user.IsVerified {
		return nil // 已經驗證過了
	}

	if user.VerificationCode == nil || *user.VerificationCode != code {
		return apperror.ErrInvalidVerificationCode
	}

	if user.VerificationExpiry == nil || time.Now().After(*user.VerificationExpiry) {
		return apperror.ErrVerificationCodeExpired
	}

	return svc.userRepo.SetVerified(ctx, user.ID)
}

// ResendVerificationCode 重發驗證碼。
func (svc *AuthService) ResendVerificationCode(ctx context.Context, emailAddr string) error {
	user, err := svc.userRepo.GetByEmail(ctx, emailAddr)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil // 基於安全性，隱藏使用者是否存在
		}
		return err
	}

	if user.IsVerified {
		return nil
	}

	code, err := auth.GenerateVerificationCode()
	if err != nil {
		return err
	}
	expiry := time.Now().Add(10 * time.Minute)

	if err := svc.userRepo.UpdateVerification(ctx, user.ID, code, expiry); err != nil {
		return err
	}

	if svc.emailService != nil {
		go func() {
			if err := svc.emailService.SendVerificationCode(user.Email, code, 10); err != nil {
				svc.logger.Error("重發驗證信失敗", "user_id", user.ID, "error", err)
			}
		}()
	}

	return nil
}
