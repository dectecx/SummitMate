package service

import (
	"context"
	"fmt"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type GroupEventService interface {
	CreateEvent(ctx context.Context, event *model.GroupEvent) error
	GetEvent(ctx context.Context, id string) (*model.GroupEvent, error)
	ListEvents(ctx context.Context, status *string, creatorID *string) ([]*model.GroupEvent, error)
	UpdateEvent(ctx context.Context, event *model.GroupEvent, userID string) error
	DeleteEvent(ctx context.Context, id string, userID string) error

	ApplyToEvent(ctx context.Context, app *model.GroupEventApplication) error
	ListApplications(ctx context.Context, id string, userID string) ([]*model.GroupEventApplication, error)
	ProcessApplication(ctx context.Context, eventID, userID, status, executorID string) error

	AddComment(ctx context.Context, comment *model.GroupEventComment) error
	ListComments(ctx context.Context, eventID string) ([]*model.GroupEventComment, error)
	DeleteComment(ctx context.Context, commentID string, userID string) error

	ToggleLike(ctx context.Context, eventID, userID string) (bool, error)
}

type groupEventService struct {
	repo repository.GroupEventRepository
}

func NewGroupEventService(repo repository.GroupEventRepository) GroupEventService {
	return &groupEventService{repo: repo}
}

func (s *groupEventService) CreateEvent(ctx context.Context, event *model.GroupEvent) error {
	if event.Title == "" {
		return apperror.ErrBadRequest.WithMessage("活動標題為必填")
	}
	event.Status = "open"
	return s.repo.CreateEvent(ctx, event)
}

func (s *groupEventService) GetEvent(ctx context.Context, id string) (*model.GroupEvent, error) {
	return s.repo.GetEventByID(ctx, id)
}

func (s *groupEventService) ListEvents(ctx context.Context, status *string, creatorID *string) ([]*model.GroupEvent, error) {
	return s.repo.ListEvents(ctx, status, creatorID)
}

func (s *groupEventService) UpdateEvent(ctx context.Context, event *model.GroupEvent, userID string) error {
	existing, err := s.repo.GetEventByID(ctx, event.ID)
	if err != nil {
		return err
	}
	if existing == nil {
		return apperror.ErrEventNotFound
	}
	if existing.CreatedBy != userID {
		return apperror.ErrEventAccessDenied
	}

	event.UpdatedBy = userID
	return s.repo.UpdateEvent(ctx, event)
}

func (s *groupEventService) DeleteEvent(ctx context.Context, id string, userID string) error {
	existing, err := s.repo.GetEventByID(ctx, id)
	if err != nil {
		return err
	}
	if existing == nil {
		return apperror.ErrEventNotFound
	}
	if existing.CreatedBy != userID {
		return apperror.ErrEventAccessDenied
	}

	return s.repo.DeleteEvent(ctx, id)
}

func (s *groupEventService) ApplyToEvent(ctx context.Context, app *model.GroupEventApplication) error {
	event, err := s.repo.GetEventByID(ctx, app.EventID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.Status != "open" {
		return apperror.New(400, apperror.TypeBusinessLogic, "event_not_open", fmt.Sprintf("活動目前狀態為 %s，無法報名", event.Status))
	}

	// In a real app, check if user already applied or is already a member
	// For now, let the repo (database unique constraint) handle duplicates

	app.CreatedBy = app.UserID
	app.UpdatedBy = app.UserID

	return s.repo.ApplyToEvent(ctx, app)
}

func (s *groupEventService) ListApplications(ctx context.Context, id string, userID string) ([]*model.GroupEventApplication, error) {
	event, err := s.repo.GetEventByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, apperror.ErrEventNotFound
	}
	if event.CreatedBy != userID {
		return nil, apperror.ErrEventAccessDenied
	}

	return s.repo.ListApplications(ctx, id)
}

func (s *groupEventService) ProcessApplication(ctx context.Context, eventID, userID, status, executorID string) error {
	event, err := s.repo.GetEventByID(ctx, eventID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.CreatedBy != executorID {
		return apperror.ErrEventAccessDenied
	}

	return s.repo.UpdateApplicationStatus(ctx, eventID, userID, status, executorID)
}

func (s *groupEventService) AddComment(ctx context.Context, comment *model.GroupEventComment) error {
	if comment.Content == "" {
		return apperror.ErrBadRequest.WithMessage("留言內容不可為空")
	}
	comment.CreatedBy = comment.UserID
	comment.UpdatedBy = comment.UserID
	return s.repo.AddComment(ctx, comment)
}

func (s *groupEventService) ListComments(ctx context.Context, eventID string) ([]*model.GroupEventComment, error) {
	return s.repo.ListComments(ctx, eventID)
}

func (s *groupEventService) DeleteComment(ctx context.Context, commentID string, userID string) error {
	return s.repo.DeleteComment(ctx, commentID, userID)
}

func (s *groupEventService) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	return s.repo.ToggleLike(ctx, eventID, userID)
}
