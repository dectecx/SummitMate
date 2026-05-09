package gearset

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/google/uuid"
)

// GearSetService 定義裝備組合相關的業務邏輯介面。
type GearSetService interface {
	Create(ctx context.Context, gs *GearSet) (*GearSet, error)
	Update(ctx context.Context, gs *GearSet, requestingUserID string) (*GearSet, error)
	GetByID(ctx context.Context, id uuid.UUID, requestingUserID string, providedKey *string) (*GearSet, error)
	Delete(ctx context.Context, id uuid.UUID, requestingUserID string) error
	List(ctx context.Context, limit, offset int, search string, requestingUserID string, myUploadedOnly bool) ([]*GearSet, int, error)
}

type gearSetService struct {
	logger *slog.Logger
	repo   GearSetRepository
}

func NewGearSetService(logger *slog.Logger, repo GearSetRepository) GearSetService {
	return &gearSetService{
		logger: logger.With("component", "gearset"),
		repo:   repo,
	}
}

func (s *gearSetService) Create(ctx context.Context, gs *GearSet) (*GearSet, error) {
	if gs.ID == uuid.Nil {
		gs.ID = uuid.New()
	}
	now := time.Now()
	gs.CreatedAt = now
	gs.UpdatedAt = now

	if err := s.validateGearSet(gs); err != nil {
		return nil, err
	}

	err := s.repo.Create(ctx, gs)
	if err != nil {
		return nil, err
	}
	return gs, nil
}

func (s *gearSetService) Update(ctx context.Context, gs *GearSet, requestingUserID string) (*GearSet, error) {
	existing, err := s.repo.GetByID(ctx, gs.ID)
	if err != nil {
		return nil, err
	}

	if existing.UserID != requestingUserID {
		return nil, fmt.Errorf("only the owner can update this gear set")
	}

	gs.UserID = existing.UserID
	gs.CreatedAt = existing.CreatedAt
	gs.CreatedBy = existing.CreatedBy
	gs.UpdatedAt = time.Now()
	gs.UpdatedBy = requestingUserID

	if err := s.validateGearSet(gs); err != nil {
		return nil, err
	}

	err = s.repo.Update(ctx, gs)
	if err != nil {
		return nil, err
	}
	return gs, nil
}

func (s *gearSetService) validateGearSet(gs *GearSet) error {
	switch gs.Visibility {
	case VisibilityPublic, VisibilityProtected, VisibilityPrivate:
		// valid
	default:
		return fmt.Errorf("invalid visibility: %s", gs.Visibility)
	}

	if gs.Visibility == VisibilityProtected && (gs.DownloadKey == nil || *gs.DownloadKey == "") {
		return fmt.Errorf("download_key is required for protected gear sets")
	}
	return nil
}

func (s *gearSetService) GetByID(ctx context.Context, id uuid.UUID, requestingUserID string, providedKey *string) (*GearSet, error) {
	gs, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// Owner can always access
	if gs.UserID == requestingUserID {
		return gs, nil
	}

	if gs.Visibility == VisibilityPrivate {
		return nil, fmt.Errorf("gear set is private")
	}

	if gs.Visibility == VisibilityProtected {
		if providedKey == nil || gs.DownloadKey == nil || *providedKey != *gs.DownloadKey {
			return nil, fmt.Errorf("invalid or missing download_key")
		}
	}

	return gs, nil
}

func (s *gearSetService) Delete(ctx context.Context, id uuid.UUID, requestingUserID string) error {
	gs, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	if gs.UserID != requestingUserID {
		return fmt.Errorf("only the owner can delete this gear set")
	}

	return s.repo.Delete(ctx, id)
}

func (s *gearSetService) List(ctx context.Context, limit, offset int, search string, requestingUserID string, myUploadedOnly bool) ([]*GearSet, int, error) {
	var filterUserID *string
	if myUploadedOnly {
		filterUserID = &requestingUserID
	}
	return s.repo.List(ctx, limit, offset, search, filterUserID)
}
