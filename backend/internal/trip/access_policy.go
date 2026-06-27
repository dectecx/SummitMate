package trip

import (
	"context"

	"summitmate/internal/apperror"
)

// TripAccessChecker 提供集中式行程成員／角色權限驗證。
// 此介面是跨多個 service 中重複出現的 checkTripAccess、isTripMemberOrCreator、
// requireTripMember 等樣板的唯一來源，任何 service 只需注入此介面即可完成存取控制。
type TripAccessChecker interface {
	// RequireMember 透過 tripID 從資料庫載入行程，並驗證 userID 是擁有者或成員。
	// 行程不存在時回傳 ErrTripNotFound；
	// 使用者既非擁有者也非成員時回傳 ErrTripAccessDenied。
	RequireMember(ctx context.Context, tripID, userID string) error

	// RequireMemberForTrip 功能同 RequireMember，但使用已取得的行程物件以避免重複查詢。
	RequireMemberForTrip(ctx context.Context, t *Trip, userID string) error

	// RequireOwner 僅在 userID 為行程建立者（UserID 欄位）時回傳 nil。
	// 使用已取得的行程物件以避免重複查詢。
	RequireOwner(t *Trip, userID string) error

	// RequireOwnerByID 透過 tripID 載入行程後驗證 userID 是否為擁有者。
	// 適用於尚未取得行程物件的場景。
	RequireOwnerByID(ctx context.Context, tripID, userID string) error

	// RequireRole 在 userID 持有 allowedRoles 其中一個角色時回傳 nil。
	// 若行程擁有者不在成員表中，自動視為 RoleLeader。
	RequireRole(ctx context.Context, t *Trip, userID string, allowedRoles ...string) error
}

type tripAccessChecker struct {
	tripRepo   TripRepository
	memberRepo TripMemberRepository
}

// NewTripAccessChecker 以給定的 repository 建立 TripAccessChecker 實例。
func NewTripAccessChecker(tripRepo TripRepository, memberRepo TripMemberRepository) TripAccessChecker {
	return &tripAccessChecker{tripRepo: tripRepo, memberRepo: memberRepo}
}

func (c *tripAccessChecker) RequireMember(ctx context.Context, tripID, userID string) error {
	t, err := c.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if t == nil {
		return apperror.ErrTripNotFound
	}
	return c.RequireMemberForTrip(ctx, t, userID)
}

func (c *tripAccessChecker) RequireMemberForTrip(ctx context.Context, t *Trip, userID string) error {
	if t.UserID == userID {
		return nil
	}
	isMember, err := c.memberRepo.IsMember(ctx, t.ID, userID)
	if err != nil {
		return err
	}
	if !isMember {
		return apperror.ErrTripAccessDenied
	}
	return nil
}

func (c *tripAccessChecker) RequireOwner(t *Trip, userID string) error {
	if t.UserID != userID {
		return apperror.ErrAccessDenied
	}
	return nil
}

func (c *tripAccessChecker) RequireOwnerByID(ctx context.Context, tripID, userID string) error {
	t, err := c.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if t == nil {
		return apperror.ErrTripNotFound
	}
	return c.RequireOwner(t, userID)
}

func (c *tripAccessChecker) RequireRole(ctx context.Context, t *Trip, userID string, allowedRoles ...string) error {
	role, err := c.memberRepo.GetRole(ctx, t.ID, userID)
	if err != nil {
		if t.UserID == userID {
			role = RoleLeader
		} else {
			return apperror.ErrAccessDenied
		}
	}
	for _, allowed := range allowedRoles {
		if role == allowed {
			return nil
		}
	}
	return apperror.ErrAccessDenied
}
