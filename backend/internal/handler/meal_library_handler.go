package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type MealLibraryHandler struct {
	svc *service.MealLibraryService
}

func NewMealLibraryHandler(svc *service.MealLibraryService) *MealLibraryHandler {
	return &MealLibraryHandler{svc: svc}
}

func (h *MealLibraryHandler) ListMealLibrary(w http.ResponseWriter, r *http.Request, params api.ListMealLibraryParams) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	includeArchived := false
	if params.IncludeArchived != nil {
		includeArchived = *params.IncludeArchived
	}

	items, err := h.svc.ListItems(r.Context(), userID, includeArchived)
	if err != nil {
		sendError(w, err)
		return
	}

	res := make([]api.MealLibraryItem, 0, len(items))
	for _, item := range items {
		res = append(res, mapping.ToMealLibraryItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

func (h *MealLibraryHandler) CreateMealLibraryItem(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.MealLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelMealLibraryItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), userID, &modelReq)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToMealLibraryItemResponse(createdItem))
}

func (h *MealLibraryHandler) GetMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	item, err := h.svc.GetItem(r.Context(), itemId.String(), userID)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToMealLibraryItemResponse(item))
}

func (h *MealLibraryHandler) UpdateMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.MealLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelMealLibraryItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), itemId.String(), userID, &modelReq)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToMealLibraryItemResponse(updatedItem))
}

func (h *MealLibraryHandler) DeleteMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.DeleteItem(r.Context(), itemId.String(), userID); err != nil {
		sendError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
