package interaction

import (
	"context"

	"github.com/stretchr/testify/mock"
)

type MockMessageRepository struct {
	mock.Mock
}

func (m *MockMessageRepository) CreateMessage(ctx context.Context, msg *TripMessage) error {
	args := m.Called(ctx, msg)
	return args.Error(0)
}

func (m *MockMessageRepository) GetMessageByID(ctx context.Context, id string) (*TripMessage, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripMessage), args.Error(1)
}

func (m *MockMessageRepository) ListTripMessages(ctx context.Context, tripID string) ([]*TripMessage, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*TripMessage), args.Error(1)
}

func (m *MockMessageRepository) UpdateMessage(ctx context.Context, msg *TripMessage) error {
	args := m.Called(ctx, msg)
	return args.Error(0)
}

func (m *MockMessageRepository) DeleteMessage(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

type MockPollRepository struct {
	mock.Mock
}

func (m *MockPollRepository) CreatePoll(ctx context.Context, poll *Poll) error {
	args := m.Called(ctx, poll)
	return args.Error(0)
}

func (m *MockPollRepository) GetPollByID(ctx context.Context, id string) (*Poll, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Poll), args.Error(1)
}

func (m *MockPollRepository) ListTripPolls(ctx context.Context, tripID string) ([]*Poll, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*Poll), args.Error(1)
}

func (m *MockPollRepository) UpdatePoll(ctx context.Context, poll *Poll) error {
	args := m.Called(ctx, poll)
	return args.Error(0)
}

func (m *MockPollRepository) DeletePoll(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockPollRepository) AddPollOption(ctx context.Context, opt *PollOption) error {
	args := m.Called(ctx, opt)
	return args.Error(0)
}

func (m *MockPollRepository) GetPollOption(ctx context.Context, optionID string) (*PollOption, error) {
	args := m.Called(ctx, optionID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*PollOption), args.Error(1)
}

func (m *MockPollRepository) VoteOption(ctx context.Context, pollID, optionID, userID string, allowMultiple bool) error {
	args := m.Called(ctx, pollID, optionID, userID, allowMultiple)
	return args.Error(0)
}
