package interaction

import (
	"context"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/trip"
)

// MessageService 定義行程留言相關的業務邏輯介面。
type MessageService interface {
	ListTripMessages(ctx context.Context, tripID, userID string) ([]*TripMessage, error)
	AddTripMessage(ctx context.Context, tripID, userID string, msg *TripMessage) (*TripMessage, error)
	UpdateTripMessage(ctx context.Context, tripID, messageID, userID string, msg *TripMessage) (*TripMessage, error)
	DeleteTripMessage(ctx context.Context, tripID, messageID, userID string) error
}

type messageService struct {
	logger     *slog.Logger
	repo       MessageRepository
	tripRepo   trip.TripRepository
	memberRepo trip.TripMemberRepository
}

func NewMessageService(logger *slog.Logger, repo MessageRepository, tripRepo trip.TripRepository, memberRepo trip.TripMemberRepository) MessageService {
	return &messageService{
		logger:     logger.With("component", "message"),
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

func (s *messageService) ListTripMessages(ctx context.Context, tripID, userID string) ([]*TripMessage, error) {
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

func (s *messageService) AddTripMessage(ctx context.Context, tripID, userID string, msg *TripMessage) (*TripMessage, error) {
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

func (s *messageService) UpdateTripMessage(ctx context.Context, tripID, messageID, userID string, msg *TripMessage) (*TripMessage, error) {
	existing, err := s.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if existing == nil || existing.TripID != tripID {
		return nil, apperror.ErrResourceNotFound.WithMessage("找不到該留言")
	}
	if existing.UserID != userID {
		return nil, apperror.ErrAccessDenied.WithMessage("無權限編輯此留言")
	}

	msg.ID = messageID
	msg.UpdatedBy = userID

	if err := s.repo.UpdateMessage(ctx, msg); err != nil {
		return nil, err
	}

	return s.repo.GetMessageByID(ctx, messageID)
}

func (s *messageService) DeleteTripMessage(ctx context.Context, tripID, messageID, userID string) error {
	existing, err := s.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return err
	}
	if existing == nil || existing.TripID != tripID {
		return apperror.ErrResourceNotFound.WithMessage("找不到該留言")
	}

	if existing.UserID != userID {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil || trip.UserID != userID {
			return apperror.ErrAccessDenied.WithMessage("無權限刪除此留言")
		}
	}

	if err := s.repo.DeleteMessage(ctx, messageID); err != nil {
		return err
	}
	return nil
}

func (s *messageService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err == nil && trip != nil && trip.UserID == userID {
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

func (s *messageService) buildMessageTree(messages []*TripMessage) []*TripMessage {
	var rootMessages []*TripMessage
	messageMap := make(map[string]*TripMessage)

	for _, m := range messages {
		messageMap[m.ID] = m
	}

	for _, m := range messages {
		if m.ParentID != nil && *m.ParentID != "" {
			parent, exists := messageMap[*m.ParentID]
			if exists {
				parent.Replies = append(parent.Replies, m)
			} else {
				rootMessages = append(rootMessages, m)
			}
		} else {
			rootMessages = append(rootMessages, m)
		}
	}
	return rootMessages
}

// PollService 定義行程投票相關的業務邏輯介面。
type PollService interface {
	CreateTripPoll(ctx context.Context, tripID, userID string, poll *Poll) (*Poll, error)
	ListTripPolls(ctx context.Context, tripID, userID string) ([]*Poll, error)
	GetTripPoll(ctx context.Context, tripID, pollID, userID string) (*Poll, error)
	DeleteTripPoll(ctx context.Context, tripID, pollID, userID string) error
	AddPollOption(ctx context.Context, tripID, pollID, userID string, text string) (*Poll, error)
	VoteOption(ctx context.Context, tripID, pollID, optionID, userID string) (*Poll, error)
}

type pollService struct {
	logger     *slog.Logger
	repo       PollRepository
	tripRepo   trip.TripRepository
	memberRepo trip.TripMemberRepository
}

func NewPollService(logger *slog.Logger, repo PollRepository, tripRepo trip.TripRepository, memberRepo trip.TripMemberRepository) PollService {
	return &pollService{
		logger:     logger.With("component", "poll"),
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

func (s *pollService) CreateTripPoll(ctx context.Context, tripID, userID string, poll *Poll) (*Poll, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	poll.TripID = tripID
	poll.Status = "open"
	poll.CreatedBy = userID
	poll.UpdatedBy = userID

	if err := s.repo.CreatePoll(ctx, poll); err != nil {
		return nil, err
	}
	return poll, nil
}

func (s *pollService) ListTripPolls(ctx context.Context, tripID, userID string) ([]*Poll, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.repo.ListTripPolls(ctx, tripID)
}

func (s *pollService) GetTripPoll(ctx context.Context, tripID, pollID, userID string) (*Poll, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	poll, err := s.repo.GetPollByID(ctx, pollID)
	if err != nil {
		return nil, err
	}
	if poll == nil || poll.TripID != tripID {
		return nil, apperror.ErrResourceNotFound.WithMessage("找不到投票活動")
	}
	return poll, nil
}

func (s *pollService) DeleteTripPoll(ctx context.Context, tripID, pollID, userID string) error {
	poll, err := s.repo.GetPollByID(ctx, pollID)
	if err != nil {
		return err
	}
	if poll == nil || poll.TripID != tripID {
		return apperror.ErrResourceNotFound.WithMessage("找不到投票活動")
	}

	if poll.CreatedBy != userID {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil || trip == nil || trip.UserID != userID {
			return apperror.ErrAccessDenied
		}
	}

	return s.repo.DeletePoll(ctx, pollID)
}

func (s *pollService) AddPollOption(ctx context.Context, tripID, pollID, userID string, text string) (*Poll, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	poll, err := s.repo.GetPollByID(ctx, pollID)
	if err != nil {
		return nil, err
	}
	if poll == nil || poll.TripID != tripID {
		return nil, apperror.ErrResourceNotFound.WithMessage("找不到投票活動")
	}

	if !poll.IsAllowAddOption && poll.CreatedBy != userID {
		return nil, apperror.ErrAccessDenied
	}

	opt := &PollOption{
		PollID:    pollID,
		Text:      text,
		CreatedBy: userID,
		UpdatedBy: userID,
	}

	if err := s.repo.AddPollOption(ctx, opt); err != nil {
		return nil, err
	}

	return s.repo.GetPollByID(ctx, pollID)
}

func (s *pollService) VoteOption(ctx context.Context, tripID, pollID, optionID, userID string) (*Poll, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	poll, err := s.repo.GetPollByID(ctx, pollID)
	if err != nil {
		return nil, err
	}
	if poll == nil || poll.TripID != tripID {
		return nil, apperror.ErrResourceNotFound.WithMessage("找不到投票活動")
	}

	if poll.Status != "open" {
		return nil, apperror.ErrResourceNotFound.WithMessage("投票活動已結束")
	}

	err = s.repo.VoteOption(ctx, pollID, optionID, userID, poll.AllowMultipleVotes)
	if err != nil {
		return nil, err
	}

	return s.repo.GetPollByID(ctx, pollID)
}

func (s *pollService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err == nil && trip != nil && trip.UserID == userID {
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
