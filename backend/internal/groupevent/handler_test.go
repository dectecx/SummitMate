package groupevent_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/groupevent"
	groupeventmocks "summitmate/internal/groupevent/mocks"
	"summitmate/internal/middleware"

	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func injectUser(r *http.Request, userID string) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), middleware.UserIDKey, userID))
}

const (
	testUserID  = "00000000-0000-0000-0000-000000000001"
	testEventID = "00000000-0000-0000-0000-000000000011"
)

func newGroupEvent(id, hostID string) *groupevent.GroupEvent {
	return &groupevent.GroupEvent{
		ID:        id,
		Title:     "Test Event",
		Category:  groupevent.CategoryHiking,
		Location:  "Taipei",
		StartDate: time.Now(),
		HostID:    hostID,
		HostName:  "Test Host",
		Status:    "open",
		CreatedBy: hostID,
		UpdatedBy: hostID,
	}
}

// ─── GetGroupEvents ────────────────────────────────────────────────────────────

func TestGroupEventHandler_GetGroupEvents(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given valid request, When calling GetGroupEvents, Then it returns 200 with list", func(t *testing.T) {
		userID := testUserID
		events := []*groupevent.GroupEvent{newGroupEvent(testEventID, userID)}

		mockSvc.On("ListEvents",
			mock.Anything, (*string)(nil), (*groupevent.Category)(nil), (*string)(nil),
			1, 20, "", testUserID,
		).Return(events, 1, false, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/group-events", nil), userID)
		w := httptest.NewRecorder()

		handler.GetGroupEvents(w, req, api.GetGroupEventsParams{})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp api.GroupEventPaginationResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, resp.Items, 1)
		mockSvc.AssertExpectations(t)
	})
}

// ─── PostGroupEvents ───────────────────────────────────────────────────────────

func TestGroupEventHandler_PostGroupEvents(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given valid body, When calling PostGroupEvents, Then it returns 201", func(t *testing.T) {
		now := openapi_types.Date{Time: time.Now()}
		reqBody := api.GroupEventRequest{
			Title:     "Summit Hike",
			Category:  string(groupevent.CategoryHiking),
			Location:  "Mt. Jade",
			StartDate: now,
		}
		body, _ := json.Marshal(reqBody)

		mockSvc.On("CreateEvent", mock.Anything, mock.AnythingOfType("*groupevent.GroupEvent")).
			Run(func(args mock.Arguments) {
				ev := args.Get(1).(*groupevent.GroupEvent)
				ev.ID = testEventID
				ev.HostID = testUserID
				ev.Status = "open"
				ev.CreatedBy = testUserID
				ev.UpdatedBy = testUserID
			}).
			Return(nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/group-events", bytes.NewBuffer(body)), testUserID)
		w := httptest.NewRecorder()

		handler.PostGroupEvents(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("Given no auth context, When calling PostGroupEvents, Then it returns 401", func(t *testing.T) {
		req := httptest.NewRequest("POST", "/group-events", bytes.NewBuffer([]byte("{}")))
		w := httptest.NewRecorder()

		handler.PostGroupEvents(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── GetGroupEventsId ──────────────────────────────────────────────────────────

func TestGroupEventHandler_GetGroupEventsId(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given existing event, When calling GetGroupEventsId, Then it returns 200", func(t *testing.T) {
		userID := testUserID
		evID := openapi_types.UUID{}
		ev := newGroupEvent(evID.String(), userID)

		mockSvc.On("GetEvent", mock.Anything, evID.String(), userID).Return(ev, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/group-events/"+evID.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.GetGroupEventsId(w, req, evID)

		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("Given nil event returned, When calling GetGroupEventsId, Then it returns 404", func(t *testing.T) {
		userID := testUserID
		evID := openapi_types.UUID{}

		mockSvc.On("GetEvent", mock.Anything, evID.String(), userID).Return((*groupevent.GroupEvent)(nil), nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/group-events/"+evID.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.GetGroupEventsId(w, req, evID)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

// ─── DeleteGroupEventsId ──────────────────────────────────────────────────────

func TestGroupEventHandler_DeleteGroupEventsId(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given owner request, When calling DeleteGroupEventsId, Then it returns 204", func(t *testing.T) {
		userID := testUserID
		evID := openapi_types.UUID{}

		mockSvc.On("DeleteEvent", mock.Anything, evID.String(), userID).Return(nil).Once()

		req := injectUser(httptest.NewRequest("DELETE", "/group-events/"+evID.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.DeleteGroupEventsId(w, req, evID)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling DeleteGroupEventsId, Then it returns 401", func(t *testing.T) {
		evID := openapi_types.UUID{}
		req := httptest.NewRequest("DELETE", "/group-events/"+evID.String(), nil)
		w := httptest.NewRecorder()

		handler.DeleteGroupEventsId(w, req, evID)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── PostGroupEventsIdLike ────────────────────────────────────────────────────

func TestGroupEventHandler_PostGroupEventsIdLike(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given valid user, When toggling like, Then it returns 200 with liked status", func(t *testing.T) {
		userID := testUserID
		evID := openapi_types.UUID{}

		mockSvc.On("ToggleLike", mock.Anything, evID.String(), userID).Return(true, nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/group-events/"+evID.String()+"/like", nil), userID)
		w := httptest.NewRecorder()

		handler.PostGroupEventsIdLike(w, req, evID)

		assert.Equal(t, http.StatusOK, w.Code)
		var resp map[string]bool
		json.NewDecoder(w.Body).Decode(&resp)
		assert.True(t, resp["is_liked"])
		mockSvc.AssertExpectations(t)
	})
}

// ─── PostGroupEventsIdComments ─────────────────────────────────────────────────

func TestGroupEventHandler_PostGroupEventsIdComments(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given valid body, When posting comment, Then it returns 201", func(t *testing.T) {
		evID := openapi_types.UUID{}
		reqBody := api.GroupEventCommentRequest{Content: "Great event!"}
		body, _ := json.Marshal(reqBody)

		mockSvc.On("AddComment", mock.Anything, mock.AnythingOfType("*groupevent.GroupEventComment")).
			Run(func(args mock.Arguments) {
				c := args.Get(1).(*groupevent.GroupEventComment)
				c.ID = testEventID
				c.EventID = evID.String()
				c.UserID = testUserID
				c.CreatedBy = testUserID
				c.UpdatedBy = testUserID
			}).
			Return(nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/group-events/"+evID.String()+"/comments", bytes.NewBuffer(body)), testUserID)
		w := httptest.NewRecorder()

		handler.PostGroupEventsIdComments(w, req, evID)

		assert.Equal(t, http.StatusCreated, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

// ─── GetGroupEventsMy ─────────────────────────────────────────────────────────

func TestGroupEventHandler_GetGroupEventsMy(t *testing.T) {
	mockSvc := new(groupeventmocks.MockGroupEventService)
	handler := groupevent.NewGroupEventHandler(mockSvc)

	t.Run("Given auth user, When calling GetGroupEventsMy, Then it returns 200", func(t *testing.T) {
		userID := testUserID
		listType := api.Host
		events := []*groupevent.GroupEvent{newGroupEvent(testEventID, userID)}

		mockSvc.On("ListMyEvents", mock.Anything, testUserID, string(listType), 1, 20).
			Return(events, 1, false, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/group-events/my", nil), testUserID)
		w := httptest.NewRecorder()

		handler.GetGroupEventsMy(w, req, api.GetGroupEventsMyParams{Type: listType})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp api.GroupEventPaginationResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, resp.Items, 1)
		mockSvc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling GetGroupEventsMy, Then it returns 401", func(t *testing.T) {
		listType := api.Host
		req := httptest.NewRequest("GET", "/group-events/my", nil)
		w := httptest.NewRecorder()

		handler.GetGroupEventsMy(w, req, api.GetGroupEventsMyParams{Type: listType})

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}
