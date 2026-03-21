package service

import (
	"context"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type MessageService struct {
	logger     *slog.Logger
	repo       repository.MessageRepository
	tripRepo   *repository.TripRepository
	memberRepo *repository.TripMemberRepository
}

func NewMessageService(logger *slog.Logger, repo repository.MessageRepository, tripRepo *repository.TripRepository, memberRepo *repository.TripMemberRepository) *MessageService {
	return &MessageService{
		logger:     logger.With("component", "message"),
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

// ListTripMessages fetches messages and builds the reply tree structure.
func (s *MessageService) ListTripMessages(ctx context.Context, tripID, userID string) ([]*model.TripMessage, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		s.logger.WarnContext(ctx, "嘗試讀取行程留言但權限不足", "trip_id", tripID, "user_id", userID)
		return nil, apperror.ErrAccessDenied
	}

	messages, err := s.repo.ListTripMessages(ctx, tripID)
	if err != nil {
		return nil, err
	}

	return s.buildMessageTree(messages), nil
}

func (s *MessageService) AddTripMessage(ctx context.Context, tripID, userID string, msg *model.TripMessage) (*model.TripMessage, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	msg.TripID = tripID
	msg.UserID = userID
	msg.CreatedBy = userID
	msg.UpdatedBy = userID

	if err := s.repo.CreateMessage(ctx, msg); err != nil {
		s.logger.ErrorContext(ctx, "新增行程留言失敗", "trip_id", tripID, "user_id", userID, "parent_id", msg.ParentID, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "新增行程留言成功", "message_id", msg.ID, "trip_id", tripID, "user_id", userID)
	return msg, nil
}

func (s *MessageService) UpdateTripMessage(ctx context.Context, tripID, messageID, userID string, msg *model.TripMessage) (*model.TripMessage, error) {
	existing, err := s.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if existing == nil || existing.TripID != tripID {
		return nil, apperror.ErrResourceNotFound.WithMessage("找不到該留言")
	}
	// Only the author can edit their message
	if existing.UserID != userID {
		return nil, apperror.ErrAccessDenied.WithMessage("無權限編輯此留言")
	}

	msg.ID = messageID
	msg.UpdatedBy = userID

	if err := s.repo.UpdateMessage(ctx, msg); err != nil {
		return nil, err
	}

	// Fetch the updated one to get full struct including display name etc
	return s.repo.GetMessageByID(ctx, messageID)
}

func (s *MessageService) DeleteTripMessage(ctx context.Context, tripID, messageID, userID string) error {
	existing, err := s.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return err
	}
	if existing == nil || existing.TripID != tripID {
		return apperror.ErrResourceNotFound.WithMessage("找不到該留言")
	}

	// Only author or trip creator can delete
	if existing.UserID != userID {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil || trip.UserID != userID {
			return apperror.ErrAccessDenied.WithMessage("無權限刪除此留言")
		}
	}

	if err := s.repo.DeleteMessage(ctx, messageID); err != nil {
		s.logger.ErrorContext(ctx, "刪除行程留言失敗", "message_id", messageID, "trip_id", tripID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "行程留言刪除成功", "message_id", messageID, "trip_id", tripID, "user_id", userID)
	return nil
}

func (s *MessageService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err == nil && trip.UserID == userID {
		return true
	}
	members, err := s.memberRepo.ListByTripID(ctx, tripID)
	if err == nil {
		for _, m := range members {
			if m.UserID == userID {
				return true
			}
		}
	}
	return false
}

func (s *MessageService) buildMessageTree(messages []*model.TripMessage) []*model.TripMessage {
	var rootMessages []*model.TripMessage
	messageMap := make(map[string]*model.TripMessage)

	// First pass: populate map
	for _, m := range messages {
		messageMap[m.ID] = m
	}

	// Second pass: attach children to parents
	for _, m := range messages {
		if m.ParentID != nil && *m.ParentID != "" {
			parent, exists := messageMap[*m.ParentID]
			if exists {
				parent.Replies = append(parent.Replies, m)
			} else {
				// Parent deleted or missing, attach to root
				rootMessages = append(rootMessages, m)
			}
		} else {
			rootMessages = append(rootMessages, m)
		}
	}
	return rootMessages
}
