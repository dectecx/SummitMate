package favorite_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/favorite"
	"summitmate/internal/middleware"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// ─── Mock Service ─────────────────────────────────────────────────────────────

type mockFavoriteService struct{ mock.Mock }

func (m *mockFavoriteService) ListFavorites(ctx context.Context, userID string, page, limit int) ([]*favorite.Favorite, int, bool, error) {
	args := m.Called(ctx, userID, page, limit)
	return args.Get(0).([]*favorite.Favorite), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *mockFavoriteService) AddFavorite(ctx context.Context, userID, targetID, favType string) (*favorite.Favorite, error) {
	args := m.Called(ctx, userID, targetID, favType)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*favorite.Favorite), args.Error(1)
}

func (m *mockFavoriteService) RemoveFavorite(ctx context.Context, targetID, userID, favType string) error {
	return m.Called(ctx, targetID, userID, favType).Error(0)
}

func (m *mockFavoriteService) BatchUpdateFavorites(ctx context.Context, userID string, items []favorite.BatchFavoriteItem) error {
	return m.Called(ctx, userID, items).Error(0)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func injectUser(r *http.Request, userID string) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), middleware.UserIDKey, userID))
}

const (
	testUserID     = "00000000-0000-0000-0000-000000000001"
	testFavoriteID = "00000000-0000-0000-0000-000000000010"
	testTargetID   = "00000000-0000-0000-0000-000000000020"
)

func newFavorite(targetID, userID, favType string) *favorite.Favorite {
	return &favorite.Favorite{
		ID:        testFavoriteID,
		UserID:    userID,
		TargetID:  targetID,
		Type:      favType,
		CreatedAt: time.Now(),
		CreatedBy: userID,
		UpdatedAt: time.Now(),
		UpdatedBy: userID,
	}
}

// ─── ListFavorites ────────────────────────────────────────────────────────────

func TestFavoriteHandler_ListFavorites(t *testing.T) {
	svc := new(mockFavoriteService)
	handler := favorite.NewFavoriteHandler(svc)

	t.Run("Given valid auth, When calling ListFavorites, Then it returns 200 with items", func(t *testing.T) {
		favs := []*favorite.Favorite{newFavorite(testTargetID, testUserID, favorite.TypeMountain)}

		svc.On("ListFavorites", mock.Anything, testUserID, 1, 20).
			Return(favs, 1, false, nil).Once()

		req := injectUser(httptest.NewRequest("GET", "/favorites", nil), testUserID)
		w := httptest.NewRecorder()

		handler.ListFavorites(w, req, api.ListFavoritesParams{})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp api.FavoritePaginationResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Len(t, resp.Items, 1)
		svc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling ListFavorites, Then it returns 401", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/favorites", nil)
		w := httptest.NewRecorder()

		handler.ListFavorites(w, req, api.ListFavoritesParams{})

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── AddFavorite ──────────────────────────────────────────────────────────────

func TestFavoriteHandler_AddFavorite(t *testing.T) {
	svc := new(mockFavoriteService)
	handler := favorite.NewFavoriteHandler(svc)

	t.Run("Given valid body, When calling AddFavorite, Then it returns 201", func(t *testing.T) {
		targetID := uuid.New()
		reqBody := api.FavoriteRequest{
			TargetId: openapi_types.UUID(targetID),
			Type:     api.FavoriteType(favorite.TypeMountain),
		}
		body, _ := json.Marshal(reqBody)
		fav := newFavorite(targetID.String(), testUserID, favorite.TypeMountain)

		svc.On("AddFavorite", mock.Anything, testUserID, targetID.String(), favorite.TypeMountain).
			Return(fav, nil).Once()

		req := injectUser(httptest.NewRequest("POST", "/favorites", bytes.NewBuffer(body)), testUserID)
		w := httptest.NewRecorder()

		handler.AddFavorite(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		svc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling AddFavorite, Then it returns 401", func(t *testing.T) {
		targetID := uuid.New()
		body, _ := json.Marshal(api.FavoriteRequest{
			TargetId: openapi_types.UUID(targetID),
			Type:     api.FavoriteType(favorite.TypeMountain),
		})
		req := httptest.NewRequest("POST", "/favorites", bytes.NewBuffer(body))
		w := httptest.NewRecorder()

		handler.AddFavorite(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── RemoveFavorite ───────────────────────────────────────────────────────────

func TestFavoriteHandler_RemoveFavorite(t *testing.T) {
	svc := new(mockFavoriteService)
	handler := favorite.NewFavoriteHandler(svc)

	t.Run("Given valid request, When calling RemoveFavorite, Then it returns 204", func(t *testing.T) {
		targetID := uuid.New()
		openapiTargetID := openapi_types.UUID(targetID)
		favType := api.FavoriteType(favorite.TypeMountain)

		svc.On("RemoveFavorite", mock.Anything, targetID.String(), testUserID, favorite.TypeMountain).
			Return(nil).Once()

		req := injectUser(httptest.NewRequest("DELETE", "/favorites/"+targetID.String(), nil), testUserID)
		w := httptest.NewRecorder()

		handler.RemoveFavorite(w, req, openapiTargetID, api.RemoveFavoriteParams{Type: favType})

		assert.Equal(t, http.StatusNoContent, w.Code)
		svc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling RemoveFavorite, Then it returns 401", func(t *testing.T) {
		targetID := uuid.New()
		openapiTargetID := openapi_types.UUID(targetID)
		favType := api.FavoriteType(favorite.TypeMountain)
		req := httptest.NewRequest("DELETE", "/favorites/"+targetID.String(), nil)
		w := httptest.NewRecorder()

		handler.RemoveFavorite(w, req, openapiTargetID, api.RemoveFavoriteParams{Type: favType})

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ─── BatchUpdateFavorites ─────────────────────────────────────────────────────

func TestFavoriteHandler_BatchUpdateFavorites(t *testing.T) {
	svc := new(mockFavoriteService)
	handler := favorite.NewFavoriteHandler(svc)

	t.Run("Given valid batch body, When calling BatchUpdateFavorites, Then it returns 200", func(t *testing.T) {
		targetID := uuid.New()
		isFav := true
		reqBody := api.BatchUpdateFavoritesJSONBody{
			{
				TargetId:   openapi_types.UUID(targetID),
				Type:       api.FavoriteType(favorite.TypeMountain),
				IsFavorite: isFav,
			},
		}
		body, _ := json.Marshal(reqBody)

		svc.On("BatchUpdateFavorites", mock.Anything, testUserID, mock.AnythingOfType("[]favorite.BatchFavoriteItem")).
			Return(nil).Once()

		req := injectUser(httptest.NewRequest("PUT", "/favorites/batch", bytes.NewBuffer(body)), testUserID)
		w := httptest.NewRecorder()

		handler.BatchUpdateFavorites(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		svc.AssertExpectations(t)
	})

	t.Run("Given no auth, When calling BatchUpdateFavorites, Then it returns 401", func(t *testing.T) {
		req := httptest.NewRequest("PUT", "/favorites/batch", bytes.NewBuffer([]byte("[]")))
		w := httptest.NewRecorder()

		handler.BatchUpdateFavorites(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}
