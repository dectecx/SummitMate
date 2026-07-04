package gearset_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/gearset"
	"summitmate/internal/middleware"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// ─── Mock Service ─────────────────────────────────────────────────────────────

type mockGearSetService struct{ mock.Mock }

func (m *mockGearSetService) Create(ctx context.Context, gs *gearset.GearSet, userID string) (*gearset.GearSet, error) {
	args := m.Called(ctx, gs, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*gearset.GearSet), args.Error(1)
}

func (m *mockGearSetService) Update(ctx context.Context, gs *gearset.GearSet, userID string) (*gearset.GearSet, error) {
	args := m.Called(ctx, gs, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*gearset.GearSet), args.Error(1)
}

func (m *mockGearSetService) GetByID(ctx context.Context, id uuid.UUID, userID string, key *string) (*gearset.GearSet, error) {
	args := m.Called(ctx, id, userID, key)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*gearset.GearSet), args.Error(1)
}

func (m *mockGearSetService) Delete(ctx context.Context, id uuid.UUID, userID string) error {
	return m.Called(ctx, id, userID).Error(0)
}

func (m *mockGearSetService) List(ctx context.Context, limit, offset int, search, userID string, myOnly bool) ([]*gearset.GearSet, int, error) {
	args := m.Called(ctx, limit, offset, search, userID, myOnly)
	return args.Get(0).([]*gearset.GearSet), args.Int(1), args.Error(2)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func injectUser(r *http.Request, userID string) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), middleware.UserIDKey, userID))
}

func newGearSet(id uuid.UUID, userID string) *gearset.GearSet {
	return &gearset.GearSet{
		ID:         id,
		Title:      "Test Gear Set",
		Visibility: gearset.VisibilityPublic,
		UserID:     userID,
		CreatedBy:  userID,
		UpdatedBy:  userID,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
}

// ─── ListGearSets ─────────────────────────────────────────────────────────────

func TestGearSetHandler_ListGearSets(t *testing.T) {
	svc := new(mockGearSetService)
	handler := gearset.NewGearSetHandler(svc)

	t.Run("Given no filters, When calling ListGearSets, Then it returns 200 with list", func(t *testing.T) {
		sets := []*gearset.GearSet{newGearSet(uuid.New(), "user-1")}
		svc.On("List", mock.Anything, 20, 0, "", "", false).
			Return(sets, 1, nil).Once()

		req := httptest.NewRequest("GET", "/gear-sets", nil)
		w := httptest.NewRecorder()

		handler.ListGearSets(w, req, api.ListGearSetsParams{})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp api.GearSetListResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, *resp.Data, 1)
		svc.AssertExpectations(t)
	})

	t.Run("Given myUploaded=true without auth, When calling ListGearSets, Then it returns 401", func(t *testing.T) {
		myUploaded := true
		req := httptest.NewRequest("GET", "/gear-sets?my_uploaded=true", nil)
		w := httptest.NewRecorder()

		handler.ListGearSets(w, req, api.ListGearSetsParams{MyUploaded: &myUploaded})

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── CreateGearSet ────────────────────────────────────────────────────────────

func TestGearSetHandler_CreateGearSet(t *testing.T) {
	svc := new(mockGearSetService)
	handler := gearset.NewGearSetHandler(svc)

	t.Run("Given valid body, When calling CreateGearSet, Then it returns 201", func(t *testing.T) {
		userID := "user-1"
		reqBody := api.GearSetCreateRequest{
			Title:      "My Gear",
			Visibility: api.GearSetCreateRequestVisibility("public"),
			Items:      []api.GearSetItemRequest{},
		}
		body, _ := json.Marshal(reqBody)
		created := newGearSet(uuid.New(), userID)

		svc.On("Create", mock.Anything, mock.AnythingOfType("*gearset.GearSet"), userID).
			Return(created, nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/gear-sets", bytes.NewBuffer(body)), userID)
		w := httptest.NewRecorder()

		handler.CreateGearSet(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		svc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling CreateGearSet, Then it returns 401", func(t *testing.T) {
		body, _ := json.Marshal(api.GearSetCreateRequest{Title: "X", Items: []api.GearSetItemRequest{}})
		req := httptest.NewRequest("POST", "/gear-sets", bytes.NewBuffer(body))
		w := httptest.NewRecorder()

		handler.CreateGearSet(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── GetGearSet ───────────────────────────────────────────────────────────────

func TestGearSetHandler_GetGearSet(t *testing.T) {
	svc := new(mockGearSetService)
	handler := gearset.NewGearSetHandler(svc)

	t.Run("Given existing gear set, When calling GetGearSet, Then it returns 200", func(t *testing.T) {
		userID := "user-1"
		id := uuid.New()
		openapiID := openapi_types.UUID(id)
		gs := newGearSet(id, userID)

		svc.On("GetByID", mock.Anything, id, userID, (*string)(nil)).
			Return(gs, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/gear-sets/"+id.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.GetGearSet(w, req, openapiID, api.GetGearSetParams{})

		assert.Equal(t, http.StatusOK, w.Code)
		svc.AssertExpectations(t)
	})
}

// ─── DeleteGearSet ────────────────────────────────────────────────────────────

func TestGearSetHandler_DeleteGearSet(t *testing.T) {
	svc := new(mockGearSetService)
	handler := gearset.NewGearSetHandler(svc)

	t.Run("Given owner request, When calling DeleteGearSet, Then it returns 204", func(t *testing.T) {
		userID := "user-1"
		id := uuid.New()
		openapiID := openapi_types.UUID(id)

		svc.On("Delete", mock.Anything, id, userID).Return(nil).Once()

		req := injectUser(httptest.NewRequest("DELETE", "/gear-sets/"+id.String(), nil), userID)
		w := httptest.NewRecorder()

		handler.DeleteGearSet(w, req, openapiID)

		assert.Equal(t, http.StatusNoContent, w.Code)
		svc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling DeleteGearSet, Then it returns 401", func(t *testing.T) {
		id := uuid.New()
		openapiID := openapi_types.UUID(id)
		req := httptest.NewRequest("DELETE", "/gear-sets/"+id.String(), nil)
		w := httptest.NewRecorder()

		handler.DeleteGearSet(w, req, openapiID)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── UpdateGearSet ────────────────────────────────────────────────────────────

func TestGearSetHandler_UpdateGearSet(t *testing.T) {
	svc := new(mockGearSetService)
	handler := gearset.NewGearSetHandler(svc)

	t.Run("Given valid body, When calling UpdateGearSet, Then it returns 200", func(t *testing.T) {
		userID := "user-1"
		id := uuid.New()
		openapiID := openapi_types.UUID(id)
		reqBody := api.GearSetCreateRequest{
			Title:      "Updated Gear",
			Visibility: api.GearSetCreateRequestVisibility("public"),
			Items:      []api.GearSetItemRequest{},
		}
		body, _ := json.Marshal(reqBody)
		updated := newGearSet(id, userID)
		updated.Title = "Updated Gear"

		svc.On("Update", mock.Anything, mock.AnythingOfType("*gearset.GearSet"), userID).
			Return(updated, nil).Once()

		req := injectUser(httptest.NewRequest("PUT", "/gear-sets/"+id.String(), bytes.NewBuffer(body)), userID)
		w := httptest.NewRecorder()

		handler.UpdateGearSet(w, req, openapiID)

		assert.Equal(t, http.StatusOK, w.Code)
		svc.AssertExpectations(t)
	})
}
