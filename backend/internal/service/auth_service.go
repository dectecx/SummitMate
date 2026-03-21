package service

import (
	"context"
	"errors"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

// AuthService 封裝認證相關的業務邏輯 (註冊、登入、取得使用者)。
type AuthService struct {
	userRepo     *repository.UserRepository // 使用者資料存取層
	tokenManager *auth.TokenManager         // JWT Token 管理器
}

// NewAuthService 建立 AuthService 實例。
func NewAuthService(userRepo *repository.UserRepository, tokenManager *auth.TokenManager) *AuthService {
	return &AuthService{
		userRepo:     userRepo,
		tokenManager: tokenManager,
	}
}

// Register 處理使用者註冊流程：
//  1. 檢查 Email 是否已被使用
//  2. 將密碼以 bcrypt 雜湊
//  3. 寫入資料庫
//  4. 簽發 JWT Token
//
// 回傳新建的 User、JWT Token、或錯誤。
func (svc *AuthService) Register(ctx context.Context, email, password, displayName string) (*model.User, string, error) {
	// 檢查 Email 是否已存在
	_, err := svc.userRepo.GetByEmail(ctx, email)
	if err == nil {
		return nil, "", apperror.ErrEmailExists
	}
	if !errors.Is(err, repository.ErrNotFound) {
		return nil, "", err // 資料庫錯誤
	}

	// 雜湊密碼
	hash, err := auth.HashPassword(password)
	if err != nil {
		return nil, "", err
	}

	// 寫入資料庫
	newUser := &model.User{
		Email:        email,
		PasswordHash: hash,
		DisplayName:  displayName,
	}
	createdUser, err := svc.userRepo.Create(ctx, newUser)
	if err != nil {
		return nil, "", err
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
			return nil, "", apperror.ErrInvalidCredentials
		}
		return nil, "", err
	}

	// 驗證密碼
	if !auth.CheckPasswordHash(password, user.PasswordHash) {
		return nil, "", apperror.ErrInvalidCredentials
	}

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
