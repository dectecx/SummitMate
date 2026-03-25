package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/repository"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type FavoriteHandler struct {
	service service.FavoriteService
}

func NewFavoriteHandler(service service.FavoriteService) *FavoriteHandler {
	return &FavoriteHandler{service: service}
}

func (h *FavoriteHandler) ListFavorites(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	favs, err := h.service.ListFavorites(r.Context(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	resp := make([]api.Favorite, len(favs))
	for i, f := range favs {
		resp[i] = mapping.ToFavoriteResponse(f)
	}
	sendJSON(w, http.StatusOK, resp)
}

func (h *FavoriteHandler) AddFavorite(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.FavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	fav, err := h.service.AddFavorite(r.Context(), userID, req.TargetId.String(), req.Type)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToFavoriteResponse(fav))
}

func (h *FavoriteHandler) RemoveFavorite(w http.ResponseWriter, r *http.Request, targetID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.service.RemoveFavorite(r.Context(), targetID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *FavoriteHandler) BatchUpdateFavorites(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.BatchUpdateFavoritesJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []repository.BatchFavoriteItem
	for _, req := range reqBody {
		items = append(items, repository.BatchFavoriteItem{
			TargetID:   req.TargetId.String(),
			Type:       req.Type,
			IsFavorite: req.IsFavorite,
		})
	}

	if err := h.service.BatchUpdateFavorites(r.Context(), userID, items); err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
