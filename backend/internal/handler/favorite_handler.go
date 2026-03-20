package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type FavoriteHandler struct {
	service *service.FavoriteService
}

func NewFavoriteHandler(service *service.FavoriteService) *FavoriteHandler {
	return &FavoriteHandler{service: service}
}

func (h *FavoriteHandler) ListFavorites(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	favs, err := h.service.ListFavorites(r.Context(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "無法取得收藏列表")
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
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.FavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
		return
	}

	fav, err := h.service.AddFavorite(r.Context(), userID, req.TargetId.String(), req.Type)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "新增收藏失敗")
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToFavoriteResponse(fav))
}

func (h *FavoriteHandler) RemoveFavorite(w http.ResponseWriter, r *http.Request, targetID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	err := h.service.RemoveFavorite(r.Context(), targetID.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusNotFound, "找不到該收藏")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
