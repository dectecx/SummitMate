package favorite

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	"summitmate/internal/middleware"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type FavoriteHandler struct {
	service FavoriteService
}

func NewFavoriteHandler(service FavoriteService) *FavoriteHandler {
	return &FavoriteHandler{service: service}
}

func (h *FavoriteHandler) ListFavorites(w http.ResponseWriter, r *http.Request, params api.ListFavoritesParams) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	page := 1
	if params.Page != nil {
		page = *params.Page
	}
	limit := 20
	if params.Limit != nil {
		limit = *params.Limit
	}

	favs, total, hasMore, err := h.service.ListFavorites(r.Context(), userID, page, limit)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	items := make([]api.Favorite, len(favs))
	for i, f := range favs {
		items[i] = ToFavoriteResponse(f)
	}

	resp := api.FavoritePaginationResponse{
		Items: items,
		Pagination: api.PaginationMetadata{
			HasMore: hasMore,
			Page:    page,
			Limit:   limit,
			Total:   total,
		},
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

func (h *FavoriteHandler) AddFavorite(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.FavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	fav, err := h.service.AddFavorite(r.Context(), userID, req.TargetId.String(), req.Type)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToFavoriteResponse(fav))
}

func (h *FavoriteHandler) RemoveFavorite(w http.ResponseWriter, r *http.Request, targetID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.service.RemoveFavorite(r.Context(), targetID.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *FavoriteHandler) BatchUpdateFavorites(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.BatchUpdateFavoritesJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []BatchFavoriteItem
	for _, req := range reqBody {
		items = append(items, BatchFavoriteItem{
			TargetID:   req.TargetId.String(),
			Type:       req.Type,
			IsFavorite: req.IsFavorite,
		})
	}

	if err := h.service.BatchUpdateFavorites(r.Context(), userID, items); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
