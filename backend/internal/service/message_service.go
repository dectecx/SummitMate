package service

import (
	"context"
	"errors"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

var ErrNotFound = errors.New("message not found")

type MessageService struct {
	repo       repository.MessageRepository
	tripRepo   *repository.TripRepository
	memberRepo *repository.TripMemberRepository
}

func NewMessageService(repo repository.MessageRepository, tripRepo *repository.TripRepository, memberRepo *repository.TripMemberRepository) *MessageService {
	return &MessageService{
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

// ListTripMessages fetches messages and builds the reply tree structure.
func (s *MessageService) ListTripMessages(ctx context.Context, tripID, userID string) ([]*model.TripMessage, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	messages, err := s.repo.ListTripMessages(ctx, tripID)
	if err != nil {
		return nil, err
	}

	return s.buildMessageTree(messages), nil
}

func (s *MessageService) AddTripMessage(ctx context.Context, tripID, userID string, msg *model.TripMessage) (*model.TripMessage, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	msg.TripID = tripID
	msg.UserID = userID
	msg.CreatedBy = userID
	msg.UpdatedBy = userID

	if err := s.repo.CreateMessage(ctx, msg); err != nil {
		return nil, err
	}
	return msg, nil
}

func (s *MessageService) UpdateTripMessage(ctx context.Context, tripID, messageID, userID string, msg *model.TripMessage) (*model.TripMessage, error) {
	existing, err := s.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if existing == nil || existing.TripID != tripID {
		return nil, ErrNotFound
	}
	// Only the author can edit their message
	if existing.UserID != userID {
		return nil, ErrUnauthorizedTripAccess
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
		return ErrNotFound
	}

	// Only author or trip creator can delete
	if existing.UserID != userID {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil || trip.UserID != userID {
			return ErrUnauthorizedTripAccess
		}
	}

	return s.repo.DeleteMessage(ctx, messageID)
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
