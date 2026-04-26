package groupevent

import (
	"context"
	"fmt"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/database"
	"summitmate/internal/trip"
)

type GroupEventService interface {
	CreateEvent(ctx context.Context, event *GroupEvent) error
	GetEvent(ctx context.Context, id string) (*GroupEvent, error)
	ListEvents(ctx context.Context, status *string, category *Category, creatorID *string, page int, limit int, search string) ([]*GroupEvent, int, bool, error)
	UpdateEvent(ctx context.Context, event *GroupEvent, userID string) error
	DeleteEvent(ctx context.Context, id string, userID string) error

	ApplyToEvent(ctx context.Context, app *GroupEventApplication) error
	ListApplications(ctx context.Context, id string, userID string) ([]*GroupEventApplication, error)
	ProcessApplication(ctx context.Context, eventID, userID, status, executorID string) error

	AddComment(ctx context.Context, comment *GroupEventComment) error
	ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error)
	DeleteComment(ctx context.Context, commentID string, userID string) error

	ToggleLike(ctx context.Context, eventID, userID string) (bool, error)
	UpdateTripLink(ctx context.Context, eventID string, tripID *string, userID string) error
	UpdateTripSnapshot(ctx context.Context, eventID string, userID string) error
}

type groupEventService struct {
	logger   *slog.Logger
	db       database.Beginner
	repo     GroupEventRepository
	tripServ trip.TripService
}

func NewGroupEventService(logger *slog.Logger, db database.Beginner, repo GroupEventRepository, tripServ trip.TripService) GroupEventService {
	return &groupEventService{
		logger:   logger.With("component", "group_event"),
		db:       db,
		repo:     repo,
		tripServ: tripServ,
	}
}

func (s *groupEventService) CreateEvent(ctx context.Context, event *GroupEvent) error {
	if event.Title == "" {
		return apperror.ErrBadRequest.WithMessage("活動標題為必填")
	}
	event.Status = "open"
	if err := s.repo.CreateEvent(ctx, event); err != nil {
		s.logger.ErrorContext(ctx, "建立活動失敗", "creator_id", event.CreatedBy, "title", event.Title, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "活動建立成功", "event_id", event.ID, "creator_id", event.CreatedBy, "title", event.Title)
	return nil
}

func (s *groupEventService) GetEvent(ctx context.Context, id string) (*GroupEvent, error) {
	return s.repo.GetEventByID(ctx, id)
}

func (s *groupEventService) ListEvents(ctx context.Context, status *string, category *Category, creatorID *string, page int, limit int, search string) ([]*GroupEvent, int, bool, error) {
	return s.repo.ListEvents(ctx, status, category, creatorID, page, limit, search)
}

func (s *groupEventService) UpdateEvent(ctx context.Context, event *GroupEvent, userID string) error {
	existing, err := s.repo.GetEventByID(ctx, event.ID)
	if err != nil {
		return err
	}
	if existing == nil {
		return apperror.ErrEventNotFound
	}
	if existing.CreatedBy != userID {
		s.logger.WarnContext(ctx, "更新活動權限不足", "event_id", event.ID, "user_id", userID)
		return apperror.ErrEventAccessDenied
	}

	event.UpdatedBy = userID
	if err := s.repo.UpdateEvent(ctx, event); err != nil {
		s.logger.ErrorContext(ctx, "更新活動失敗", "event_id", event.ID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "活動更新成功", "event_id", event.ID, "user_id", userID)
	return nil
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
		s.logger.WarnContext(ctx, "刪除活動權限不足", "event_id", id, "user_id", userID)
		return apperror.ErrEventAccessDenied
	}

	if err := s.repo.DeleteEvent(ctx, id); err != nil {
		s.logger.ErrorContext(ctx, "刪除活動失敗", "event_id", id, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "活動刪除成功", "event_id", id, "user_id", userID)
	return nil
}

func (s *groupEventService) ApplyToEvent(ctx context.Context, app *GroupEventApplication) error {
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

	if err := s.repo.ApplyToEvent(ctx, app); err != nil {
		s.logger.ErrorContext(ctx, "活動報名失敗", "event_id", app.EventID, "user_id", app.UserID, "error", err)
		return err
	}

	s.logger.InfoContext(ctx, "活動報名成功", "event_id", app.EventID, "user_id", app.UserID)
	return nil
}

func (s *groupEventService) ListApplications(ctx context.Context, id string, userID string) ([]*GroupEventApplication, error) {
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
		s.logger.WarnContext(ctx, "審核活動報名權限不足", "event_id", eventID, "executor_id", executorID)
		return apperror.ErrEventAccessDenied
	}

	if err := s.repo.UpdateApplicationStatus(ctx, eventID, userID, status, executorID); err != nil {
		s.logger.ErrorContext(ctx, "更新活動報名狀態失敗", "event_id", eventID, "target_user_id", userID, "status", status, "executor_id", executorID, "error", err)
		return err
	}

	// 如果審核通過且活動有連結行程，自動將該成員加入行程 (Role: member)
	if status == ApplicationStatusApproved && event.LinkedTripID != nil {
		// 防呆：這裡 AddMember 內部已經有權限檢查與重複加入檢查，直接呼叫即可
		_, err := s.tripServ.AddMember(ctx, *event.LinkedTripID, executorID, userID)
		if err != nil {
			s.logger.ErrorContext(ctx, "自動加入行程成員失敗", "event_id", eventID, "trip_id", *event.LinkedTripID, "user_id", userID, "error", err)
			// 這裡不回傳錯誤給前端，因為報名狀態已經更新成功了。
		} else {
			s.logger.InfoContext(ctx, "自動加入行程成員完成", "event_id", eventID, "trip_id", *event.LinkedTripID, "user_id", userID)
		}
	}

	s.logger.InfoContext(ctx, "活動報名狀態更新成功", "event_id", eventID, "target_user_id", userID, "status", status, "executor_id", executorID)
	return nil
}

func (s *groupEventService) AddComment(ctx context.Context, comment *GroupEventComment) error {
	if comment.Content == "" {
		return apperror.ErrBadRequest.WithMessage("留言內容不可為空")
	}
	comment.CreatedBy = comment.UserID
	comment.UpdatedBy = comment.UserID
	return s.repo.AddComment(ctx, comment)
}

func (s *groupEventService) ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error) {
	return s.repo.ListComments(ctx, eventID)
}

func (s *groupEventService) DeleteComment(ctx context.Context, commentID string, userID string) error {
	return s.repo.DeleteComment(ctx, commentID, userID)
}

func (s *groupEventService) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	return s.repo.ToggleLike(ctx, eventID, userID)
}

func (s *groupEventService) UpdateTripLink(ctx context.Context, eventID string, tripID *string, userID string) error {
	event, err := s.repo.GetEventByID(ctx, eventID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.CreatedBy != userID {
		return apperror.ErrEventAccessDenied
	}

	if tripID != nil {
		trip, err := s.tripServ.GetTrip(ctx, *tripID, userID)
		if err != nil {
			return err
		}
		if trip == nil {
			return apperror.ErrTripNotFound
		}
	}

	return s.repo.UpdateTripLink(ctx, eventID, tripID, userID)
}

func (s *groupEventService) UpdateTripSnapshot(ctx context.Context, eventID string, userID string) error {
	event, err := s.repo.GetEventByID(ctx, eventID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.CreatedBy != userID {
		return apperror.ErrEventAccessDenied
	}
	if event.LinkedTripID == nil {
		return apperror.ErrBadRequest.WithMessage("活動尚未連結行程")
	}

	tripObj, err := s.tripServ.GetTrip(ctx, *event.LinkedTripID, userID)
	if err != nil {
		return err
	}
	itinerary, err := s.tripServ.ListItinerary(ctx, *event.LinkedTripID, userID)
	if err != nil {
		return err
	}

	snapshot := &TripSnapshot{
		Name:      tripObj.Name,
		StartDate: tripObj.StartDate,
		EndDate:   tripObj.EndDate,
	}
	for _, item := range itinerary {
		snapshot.Itinerary = append(snapshot.Itinerary, item.Name)
	}

	return s.repo.UpdateTripSnapshot(ctx, eventID, snapshot, userID)
}
