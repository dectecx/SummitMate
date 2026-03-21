package service

import (
	"context"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type PollService struct {
	repo       repository.PollRepository
	tripRepo   *repository.TripRepository
	memberRepo *repository.TripMemberRepository
}

func NewPollService(repo repository.PollRepository, tripRepo *repository.TripRepository, memberRepo *repository.TripMemberRepository) *PollService {
	return &PollService{
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

func (s *PollService) CreateTripPoll(ctx context.Context, tripID, userID string, poll *model.Poll) (*model.Poll, error) {
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

func (s *PollService) ListTripPolls(ctx context.Context, tripID, userID string) ([]*model.Poll, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	return s.repo.ListTripPolls(ctx, tripID)
}

func (s *PollService) GetTripPoll(ctx context.Context, tripID, pollID, userID string) (*model.Poll, error) {
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

func (s *PollService) DeleteTripPoll(ctx context.Context, tripID, pollID, userID string) error {
	poll, err := s.repo.GetPollByID(ctx, pollID)
	if err != nil {
		return err
	}
	if poll == nil || poll.TripID != tripID {
		return apperror.ErrResourceNotFound.WithMessage("找不到投票活動")
	}

	// Only creator of poll or creator of trip can delete poll
	if poll.CreatedBy != userID {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil || trip == nil || trip.UserID != userID {
			return apperror.ErrAccessDenied
		}
	}

	return s.repo.DeletePoll(ctx, pollID)
}

func (s *PollService) AddPollOption(ctx context.Context, tripID, pollID, userID string, text string) (*model.Poll, error) {
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

	opt := &model.PollOption{
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

func (s *PollService) VoteOption(ctx context.Context, tripID, pollID, optionID, userID string) (*model.Poll, error) {
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

func (s *PollService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
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
