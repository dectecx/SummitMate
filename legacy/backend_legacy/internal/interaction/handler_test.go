package interaction_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/interaction"
	"summitmate/internal/middleware"

	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// ─── Mock Services ─────────────────────────────────────────────────────────────

type mockMessageService struct{ mock.Mock }

func (m *mockMessageService) ListTripMessages(ctx context.Context, tripID, userID string, page, limit int) ([]*interaction.TripMessage, int, bool, error) {
	args := m.Called(ctx, tripID, userID, page, limit)
	return args.Get(0).([]*interaction.TripMessage), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *mockMessageService) AddTripMessage(ctx context.Context, tripID, userID string, msg *interaction.TripMessage) (*interaction.TripMessage, error) {
	args := m.Called(ctx, tripID, userID, msg)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*interaction.TripMessage), args.Error(1)
}

func (m *mockMessageService) UpdateTripMessage(ctx context.Context, tripID, messageID, userID string, msg *interaction.TripMessage) (*interaction.TripMessage, error) {
	args := m.Called(ctx, tripID, messageID, userID, msg)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*interaction.TripMessage), args.Error(1)
}

func (m *mockMessageService) DeleteTripMessage(ctx context.Context, tripID, messageID, userID string) error {
	return m.Called(ctx, tripID, messageID, userID).Error(0)
}

type mockPollService struct{ mock.Mock }

func (m *mockPollService) ListTripPolls(ctx context.Context, tripID, userID string, page, limit int) ([]*interaction.Poll, int, bool, error) {
	args := m.Called(ctx, tripID, userID, page, limit)
	return args.Get(0).([]*interaction.Poll), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *mockPollService) CreateTripPoll(ctx context.Context, tripID, userID string, poll *interaction.Poll) (*interaction.Poll, error) {
	args := m.Called(ctx, tripID, userID, poll)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*interaction.Poll), args.Error(1)
}

func (m *mockPollService) GetTripPoll(ctx context.Context, tripID, pollID, userID string) (*interaction.Poll, error) {
	args := m.Called(ctx, tripID, pollID, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*interaction.Poll), args.Error(1)
}

func (m *mockPollService) DeleteTripPoll(ctx context.Context, tripID, pollID, userID string) error {
	return m.Called(ctx, tripID, pollID, userID).Error(0)
}

func (m *mockPollService) AddPollOption(ctx context.Context, tripID, pollID, userID, text string) (*interaction.Poll, error) {
	args := m.Called(ctx, tripID, pollID, userID, text)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*interaction.Poll), args.Error(1)
}

func (m *mockPollService) VoteOption(ctx context.Context, tripID, pollID, optionID, userID string) (*interaction.Poll, error) {
	args := m.Called(ctx, tripID, pollID, optionID, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*interaction.Poll), args.Error(1)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func injectUser(r *http.Request, userID string) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), middleware.UserIDKey, userID))
}

const (
	testUserID    = "00000000-0000-0000-0000-000000000001"
	testMessageID = "00000000-0000-0000-0000-000000000011"
	testPollID    = "00000000-0000-0000-0000-000000000021"
)

func newMessage(id, tripID, userID string) *interaction.TripMessage {
	return &interaction.TripMessage{
		ID:        id,
		TripID:    tripID,
		UserID:    userID,
		Content:   "Hello",
		Timestamp: time.Now(),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func newPoll(id, tripID string) *interaction.Poll {
	return &interaction.Poll{
		ID:        id,
		TripID:    tripID,
		Title:     "Destination vote",
		CreatedAt: time.Now(),
		CreatedBy: testUserID,
		UpdatedAt: time.Now(),
		UpdatedBy: testUserID,
	}
}

// ─── ListTripMessages ─────────────────────────────────────────────────────────

func TestInteractionHandler_ListTripMessages(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}

	t.Run("Given valid auth, When calling ListTripMessages, Then it returns 200 with messages", func(t *testing.T) {
		userID := testUserID
		msgs := []*interaction.TripMessage{newMessage(testMessageID, tripID.String(), userID)}

		msgSvc.On("ListTripMessages", mock.Anything, tripID.String(), userID, 1, 20).
			Return(msgs, 1, false, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/trips/"+tripID.String()+"/messages", nil), userID)
		w := httptest.NewRecorder()

		handler.ListTripMessages(w, req, tripID, api.ListTripMessagesParams{})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp api.MessagePaginationResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, resp.Items, 1)
		msgSvc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling ListTripMessages, Then it returns 401", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/trips/"+tripID.String()+"/messages", nil)
		w := httptest.NewRecorder()

		handler.ListTripMessages(w, req, tripID, api.ListTripMessagesParams{})

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── AddTripMessage ───────────────────────────────────────────────────────────

func TestInteractionHandler_AddTripMessage(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}

	t.Run("Given valid body, When calling AddTripMessage, Then it returns 201", func(t *testing.T) {
		userID := testUserID
		reqBody := api.AddTripMessageJSONRequestBody{Content: "Hello world"}
		body, _ := json.Marshal(reqBody)
		created := newMessage(testMessageID, tripID.String(), userID)

		msgSvc.On("AddTripMessage", mock.Anything, tripID.String(), userID, mock.AnythingOfType("*interaction.TripMessage")).
			Return(created, nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/trips/"+tripID.String()+"/messages", bytes.NewBuffer(body)), userID)
		w := httptest.NewRecorder()

		handler.AddTripMessage(w, req, tripID)

		assert.Equal(t, http.StatusCreated, w.Code)
		msgSvc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling AddTripMessage, Then it returns 401", func(t *testing.T) {
		body, _ := json.Marshal(api.AddTripMessageJSONRequestBody{Content: "Hi"})
		req := httptest.NewRequest("POST", "/trips/"+tripID.String()+"/messages", bytes.NewBuffer(body))
		w := httptest.NewRecorder()

		handler.AddTripMessage(w, req, tripID)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── DeleteTripMessage ────────────────────────────────────────────────────────

func TestInteractionHandler_DeleteTripMessage(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}
	messageID := openapi_types.UUID{}

	t.Run("Given owner, When calling DeleteTripMessage, Then it returns 204", func(t *testing.T) {
		userID := testUserID
		msgSvc.On("DeleteTripMessage", mock.Anything, tripID.String(), messageID.String(), userID).
			Return(nil).Once()

		req := injectUser(httptest.NewRequest("DELETE", "/trips/"+tripID.String()+"/messages/"+messageID.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.DeleteTripMessage(w, req, tripID, messageID)

		assert.Equal(t, http.StatusNoContent, w.Code)
		msgSvc.AssertExpectations(t)
	})
}

// ─── ListTripPolls ────────────────────────────────────────────────────────────

func TestInteractionHandler_ListTripPolls(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}

	t.Run("Given valid auth, When calling ListTripPolls, Then it returns 200 with polls", func(t *testing.T) {
		userID := testUserID
		polls := []*interaction.Poll{newPoll(testPollID, tripID.String())}

		pollSvc.On("ListTripPolls", mock.Anything, tripID.String(), userID, 1, 20).
			Return(polls, 1, false, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/trips/"+tripID.String()+"/polls", nil), userID)
		w := httptest.NewRecorder()

		handler.ListTripPolls(w, req, tripID, api.ListTripPollsParams{})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp api.PollPaginationResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, resp.Items, 1)
		pollSvc.AssertExpectations(t)
	})
}

// ─── CreateTripPoll ───────────────────────────────────────────────────────────

func TestInteractionHandler_CreateTripPoll(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}

	t.Run("Given valid body, When calling CreateTripPoll, Then it returns 201", func(t *testing.T) {
		userID := testUserID
		reqBody := api.CreateTripPollJSONRequestBody{Title: "Where to go?"}
		body, _ := json.Marshal(reqBody)
		created := newPoll(testPollID, tripID.String())

		pollSvc.On("CreateTripPoll", mock.Anything, tripID.String(), userID, mock.AnythingOfType("*interaction.Poll")).
			Return(created, nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/trips/"+tripID.String()+"/polls", bytes.NewBuffer(body)), userID)
		w := httptest.NewRecorder()

		handler.CreateTripPoll(w, req, tripID)

		assert.Equal(t, http.StatusCreated, w.Code)
		pollSvc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling CreateTripPoll, Then it returns 401", func(t *testing.T) {
		body, _ := json.Marshal(api.CreateTripPollJSONRequestBody{Title: "Poll"})
		req := httptest.NewRequest("POST", "/trips/"+tripID.String()+"/polls", bytes.NewBuffer(body))
		w := httptest.NewRecorder()

		handler.CreateTripPoll(w, req, tripID)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── DeleteTripPoll ───────────────────────────────────────────────────────────

func TestInteractionHandler_DeleteTripPoll(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}
	pollID := openapi_types.UUID{}

	t.Run("Given owner, When calling DeleteTripPoll, Then it returns 204", func(t *testing.T) {
		userID := testUserID
		pollSvc.On("DeleteTripPoll", mock.Anything, tripID.String(), pollID.String(), userID).
			Return(nil).Once()

		req := injectUser(httptest.NewRequest("DELETE", "/trips/"+tripID.String()+"/polls/"+pollID.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.DeleteTripPoll(w, req, tripID, pollID)

		assert.Equal(t, http.StatusNoContent, w.Code)
		pollSvc.AssertExpectations(t)
	})
}

// ─── VotePollOption ───────────────────────────────────────────────────────────

func TestInteractionHandler_VotePollOption(t *testing.T) {
	msgSvc := new(mockMessageService)
	pollSvc := new(mockPollService)
	handler := interaction.NewInteractionHandler(msgSvc, pollSvc)
	tripID := openapi_types.UUID{}
	pollID := openapi_types.UUID{}
	optionID := openapi_types.UUID{}

	t.Run("Given valid vote, When calling VotePollOption, Then it returns 200 with updated poll", func(t *testing.T) {
		userID := testUserID
		updated := newPoll(pollID.String(), tripID.String())

		pollSvc.On("VoteOption", mock.Anything, tripID.String(), pollID.String(), optionID.String(), userID).
			Return(updated, nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/", nil), userID)
		w := httptest.NewRecorder()

		handler.VotePollOption(w, req, tripID, pollID, optionID)

		assert.Equal(t, http.StatusOK, w.Code)
		pollSvc.AssertExpectations(t)
	})
}
