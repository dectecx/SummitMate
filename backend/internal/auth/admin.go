package auth

import (
	"context"
	"errors"
)

// RoleAdmin 是系統管理員的角色代碼。
const RoleAdmin = "ADMIN"

// AdminChecker 以使用者資料表判斷是否為啟用中的系統管理員。
type AdminChecker struct {
	repo UserRepository
}

// NewAdminChecker 建立 AdminChecker。
func NewAdminChecker(repo UserRepository) *AdminChecker {
	return &AdminChecker{repo: repo}
}

// IsAdmin 回傳使用者是否為啟用中的管理員。找不到使用者視為非管理員。
func (c *AdminChecker) IsAdmin(ctx context.Context, userID string) (bool, error) {
	user, err := c.repo.GetByID(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return false, nil
		}
		return false, err
	}
	return user.IsActive && user.RoleCode == RoleAdmin, nil
}
