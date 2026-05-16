package groupevent

import (
	"context"
	"fmt"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	"summitmate/internal/database"
	"summitmate/internal/trip"
)

type GroupEventService interface {
	CreateEvent(ctx context.Context, event *GroupEvent) error
	GetEvent(ctx context.Context, id string, userID string) (*GroupEvent, error)
	ListEvents(ctx context.Context, status *string, category *Category, creatorID *string, page int, limit int, search string, userID string) ([]*GroupEvent, int, bool, error)
	ListMyEvents(ctx context.Context, userID string, listType string, page int, limit int) ([]*GroupEvent, int, bool, error)
	UpdateEvent(ctx context.Context, event *GroupEvent, userID string) error
	DeleteEvent(ctx context.Context, id string, userID string) error

	ApplyToEvent(ctx context.Context, app *GroupEventApplication) error
	CancelApplication(ctx context.Context, appID string, userID string) error
	GetApplication(ctx context.Context, id string) (*GroupEventApplication, error)
	ListApplications(ctx context.Context, id string, userID string) ([]*GroupEventApplication, error)
	ProcessApplication(ctx context.Context, appID, status, rejectionReason, executorID string) error

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
	authServ auth.AuthService
}

func NewGroupEventService(logger *slog.Logger, db database.Beginner, repo GroupEventRepository, tripServ trip.TripService, authServ auth.AuthService) GroupEventService {
	return &groupEventService{
		logger:   logger.With("component", "group_event"),
		db:       db,
		repo:     repo,
		tripServ: tripServ,
		authServ: authServ,
	}
}

func (s *groupEventService) CreateEvent(ctx context.Context, event *GroupEvent) error {
	if event.Title == "" {
		return apperror.ErrBadRequest.WithMessage("活動標題為必填")
	}

	// Fetch host details if not provided
	if event.HostID != "" && (event.HostName == "" || event.HostAvatar == "") {
		user, err := s.authServ.GetUserByID(ctx, event.HostID)
		if err == nil && user != nil {
			event.HostName = user.DisplayName
			event.HostAvatar = user.Avatar
		}
	}

	event.Status = "open"
	if err := s.repo.CreateEvent(ctx, event); err != nil {
		s.logger.ErrorContext(ctx, "建立活動失敗", "host_id", event.HostID, "title", event.Title, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "活動建立成功", "event_id", event.ID, "host_id", event.HostID, "title", event.Title)
	return nil
}

func (s *groupEventService) GetEvent(ctx context.Context, id string, userID string) (*GroupEvent, error) {
	return s.repo.GetEventByID(ctx, id, userID)
}

func (s *groupEventService) ListEvents(ctx context.Context, status *string, category *Category, hostID *string, page int, limit int, search string, userID string) ([]*GroupEvent, int, bool, error) {
	return s.repo.ListEvents(ctx, status, category, hostID, page, limit, search, userID)
}

func (s *groupEventService) ListMyEvents(ctx context.Context, userID string, listType string, page int, limit int) ([]*GroupEvent, int, bool, error) {
	return s.repo.ListEventsByUser(ctx, userID, listType, page, limit)
}

func (s *groupEventService) UpdateEvent(ctx context.Context, event *GroupEvent, userID string) error {
	existing, err := s.repo.GetEventByID(ctx, event.ID, userID)
	if err != nil {
		return err
	}
	if existing == nil {
		return apperror.ErrEventNotFound
	}
	if existing.HostID != userID {
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
	existing, err := s.repo.GetEventByID(ctx, id, userID)
	if err != nil {
		return err
	}
	if existing == nil {
		return apperror.ErrEventNotFound
	}
	if existing.HostID != userID {
		s.logger.WarnContext(ctx, "刪除活動權限不足", "event_id", id, "user_id", userID)
		return apperror.ErrEventAccessDenied
	}

	// 如果活動有連結行程，移除所有已加入成員的權限 (批次處理優化)
	if existing.LinkedTripID != nil {
		apps, err := s.repo.ListApplications(ctx, id)
		if err == nil {
			var memberIDs []string
			for _, app := range apps {
				if app.Status == ApplicationStatusApproved {
					memberIDs = append(memberIDs, app.UserID)
				}
			}
			if len(memberIDs) > 0 {
				_ = s.tripServ.BatchRemoveMembers(ctx, *existing.LinkedTripID, userID, memberIDs)
			}
		}
	}

	if err := s.repo.DeleteEvent(ctx, id); err != nil {
		s.logger.ErrorContext(ctx, "刪除活動失敗", "event_id", id, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "活動刪除成功", "event_id", id, "user_id", userID)
	return nil
}

func (s *groupEventService) ApplyToEvent(ctx context.Context, app *GroupEventApplication) error {
	event, err := s.repo.GetEventByID(ctx, app.EventID, app.UserID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}

	// Check if already approved or pending
	if event.MyApplicationStatus != nil {
		status := *event.MyApplicationStatus
		if status == "approved" {
			return apperror.ErrAlreadyApplied.WithMessage("您已成功報名此活動，無需再次申請")
		}
		if status == "pending" {
			return apperror.ErrBadRequest.WithMessage("您已有一筆報名申請正在審核中")
		}
	}

	if event.Status != "open" {
		return apperror.New(400, apperror.TypeBusinessLogic, "event_not_open", fmt.Sprintf("活動目前狀態為 %s，無法報名", event.Status))
	}

	// In a real app, check if user already applied or is already a member
	// For now, let the repo (database unique constraint) handle duplicates

	app.CreatedBy = app.UserID
	app.UpdatedBy = app.UserID

	// Fetch user details for the response
	user, err := s.authServ.GetUserByID(ctx, app.UserID)
	if err == nil && user != nil {
		app.UserName = user.DisplayName
		app.UserAvatar = user.Avatar
	}

	if err := s.repo.ApplyToEvent(ctx, app); err != nil {
		s.logger.ErrorContext(ctx, "活動報名失敗", "event_id", app.EventID, "user_id", app.UserID, "error", err)
		return err
	}

	s.logger.InfoContext(ctx, "活動報名成功", "event_id", app.EventID, "user_id", app.UserID)
	return nil
}

func (s *groupEventService) CancelApplication(ctx context.Context, appID string, userID string) error {
	app, err := s.repo.GetApplicationByID(ctx, appID)
	if err != nil {
		return err
	}
	if app == nil {
		return apperror.ErrResourceNotFound.WithMessage("找不到報名資料")
	}

	if app.UserID != userID {
		return apperror.ErrAccessDenied.WithMessage("無權取消他人報名")
	}

	// 如果報名已被核准且活動有連結行程，移除行程權限
	if app.Status == ApplicationStatusApproved {
		event, err := s.repo.GetEventByID(ctx, app.EventID, userID)
		if err == nil && event != nil && event.LinkedTripID != nil {
			_ = s.tripServ.RemoveMember(ctx, *event.LinkedTripID, event.CreatedBy, userID)
		}
	}

	if err := s.repo.DeleteApplication(ctx, appID); err != nil {
		s.logger.ErrorContext(ctx, "取消報名失敗", "app_id", appID, "user_id", userID, "error", err)
		return err
	}

	s.logger.InfoContext(ctx, "取消報名成功", "app_id", appID, "user_id", userID)
	return nil
}

func (s *groupEventService) GetApplication(ctx context.Context, id string) (*GroupEventApplication, error) {
	return s.repo.GetApplicationByID(ctx, id)
}

func (s *groupEventService) ListApplications(ctx context.Context, id string, userID string) ([]*GroupEventApplication, error) {
	event, err := s.repo.GetEventByID(ctx, id, userID)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, apperror.ErrEventNotFound
	}
	if event.HostID != userID {
		return nil, apperror.ErrEventAccessDenied
	}

	return s.repo.ListApplications(ctx, id)
}

func (s *groupEventService) ProcessApplication(ctx context.Context, appID, status, rejectionReason, executorID string) error {
	app, err := s.repo.GetApplicationByID(ctx, appID)
	if err != nil {
		return err
	}
	if app == nil {
		return apperror.ErrApplicationNotFound
	}

	event, err := s.repo.GetEventByID(ctx, app.EventID, executorID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.HostID != executorID {
		s.logger.WarnContext(ctx, "審核活動報名權限不足", "event_id", app.EventID, "executor_id", executorID)
		return apperror.ErrEventAccessDenied
	}

	if err := s.repo.UpdateApplicationStatus(ctx, appID, status, rejectionReason, executorID); err != nil {
		s.logger.ErrorContext(ctx, "更新活動報名狀態失敗", "app_id", appID, "status", status, "executor_id", executorID, "error", err)
		return err
	}

	// 如果審核通過且活動有連結行程，自動將該成員加入行程 (Role: member)
	if status == ApplicationStatusApproved && event.LinkedTripID != nil {
		// 防呆：這裡 AddMember 內部已經有權限檢查與重複加入檢查，直接呼叫即可
		_, err := s.tripServ.AddMember(ctx, *event.LinkedTripID, executorID, app.UserID)
		if err != nil {
			s.logger.ErrorContext(ctx, "自動加入行程成員失敗", "event_id", app.EventID, "trip_id", *event.LinkedTripID, "user_id", app.UserID, "error", err)
		} else {
			s.logger.InfoContext(ctx, "自動加入行程成員完成", "event_id", app.EventID, "trip_id", *event.LinkedTripID, "user_id", app.UserID)
		}
	} else if (status == ApplicationStatusRejected) && event.LinkedTripID != nil {
		// 如果從 Approved 變為 Rejected，需移除行程權限
		err := s.tripServ.RemoveMember(ctx, *event.LinkedTripID, executorID, app.UserID)
		if err != nil {
			s.logger.WarnContext(ctx, "移除行程成員失敗 (可能本就不是成員)", "event_id", app.EventID, "trip_id", *event.LinkedTripID, "user_id", app.UserID, "error", err)
		}
	}

	s.logger.InfoContext(ctx, "活動報名狀態更新成功", "event_id", app.EventID, "target_user_id", app.UserID, "status", status, "executor_id", executorID)
	return nil
}

func (s *groupEventService) AddComment(ctx context.Context, comment *GroupEventComment) error {
	if comment.Content == "" {
		return apperror.ErrBadRequest.WithMessage("留言內容不可為空")
	}
	comment.CreatedBy = comment.UserID
	comment.UpdatedBy = comment.UserID

	return database.WithTransaction(ctx, s.db, func(txCtx context.Context) error {
		return s.repo.AddComment(txCtx, comment)
	})
}

func (s *groupEventService) ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error) {
	return s.repo.ListComments(ctx, eventID)
}

func (s *groupEventService) DeleteComment(ctx context.Context, commentID string, userID string) error {
	return database.WithTransaction(ctx, s.db, func(txCtx context.Context) error {
		return s.repo.DeleteComment(txCtx, commentID, userID)
	})
}

func (s *groupEventService) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	var isLiked bool
	err := database.WithTransaction(ctx, s.db, func(txCtx context.Context) error {
		var err error
		isLiked, err = s.repo.ToggleLike(txCtx, eventID, userID)
		return err
	})
	return isLiked, err
}

func (s *groupEventService) UpdateTripLink(ctx context.Context, eventID string, tripID *string, userID string) error {
	event, err := s.repo.GetEventByID(ctx, eventID, userID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.HostID != userID {
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

	// 權限搬遷邏輯：如果原本有連結行程，現在更換或取消，應移除團員權限
	if event.LinkedTripID != nil && (tripID == nil || *tripID != *event.LinkedTripID) {
		apps, err := s.repo.ListApplications(ctx, eventID)
		if err == nil {
			var memberIDs []string
			for _, app := range apps {
				if app.Status == ApplicationStatusApproved {
					memberIDs = append(memberIDs, app.UserID)
				}
			}

			if len(memberIDs) > 0 {
				// 移除舊行程權限
				_ = s.tripServ.BatchRemoveMembers(ctx, *event.LinkedTripID, userID, memberIDs)
				// 如果有新行程，加入新行程權限
				if tripID != nil {
					_ = s.tripServ.BatchAddMembers(ctx, *tripID, userID, memberIDs)
				}
			}
		}
	}

	return s.repo.UpdateTripLink(ctx, eventID, tripID, userID)
}

func (s *groupEventService) UpdateTripSnapshot(ctx context.Context, eventID string, userID string) error {
	event, err := s.repo.GetEventByID(ctx, eventID, userID)
	if err != nil {
		return err
	}
	if event == nil {
		return apperror.ErrEventNotFound
	}
	if event.HostID != userID {
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
