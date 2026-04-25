package trip

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/middleware"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripHandler_ListTrips(t *testing.T) {
	mockSvc := new(MockTripService)
	handler := NewTripHandler(mockSvc)

	t.Run("Success", func(t *testing.T) {
		userID := "00000000-0000-0000-0000-000000000001"
		trips := []*Trip{
			{
				ID:        "00000000-0000-0000-0000-000000000011",
				Name:      "Trip 1",
				UserID:    userID,
				CreatedBy: userID,
				UpdatedBy: userID,
				CreatedAt: time.Now(),
			},
		}

		mockSvc.On("ListTrips", mock.Anything, userID).Return(trips, nil).Once()

		req := httptest.NewRequest("GET", "/trips", nil)
		// Inject userID into context
		ctx := context.WithValue(req.Context(), middleware.UserIDKey, userID)
		req = req.WithContext(ctx)

		w := httptest.NewRecorder()

		handler.ListTrips(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var resp []api.TripListItemResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, resp, 1)
		assert.Equal(t, trips[0].ID, resp[0].Id.String())
		mockSvc.AssertExpectations(t)
	})
}

func TestTripHandler_CreateTrip(t *testing.T) {
	mockSvc := new(MockTripService)
	handler := NewTripHandler(mockSvc)

	t.Run("Success", func(t *testing.T) {
		userID := "00000000-0000-0000-0000-000000000001"
		reqBody := api.TripCreateRequest{
			Name: "My New Trip",
		}
		jsonBody, _ := json.Marshal(reqBody)

		trip := &Trip{
			ID:        "00000000-0000-0000-0000-000000000012",
			Name:      "My New Trip",
			UserID:    userID,
			CreatedBy: userID,
			UpdatedBy: userID,
		}

		mockSvc.On("CreateTrip", mock.Anything, userID, mock.AnythingOfType("*trip.TripCreateRequest")).Return(trip, nil).Once()

		req := httptest.NewRequest("POST", "/trips", bytes.NewBuffer(jsonBody))
		ctx := context.WithValue(req.Context(), middleware.UserIDKey, userID)
		req = req.WithContext(ctx)

		w := httptest.NewRecorder()

		handler.CreateTrip(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		mockSvc.AssertExpectations(t)
	})
}
