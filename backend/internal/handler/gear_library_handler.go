package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type GearLibraryHandler struct {
	svc service.GearLibraryService
}

func NewGearLibraryHandler(svc service.GearLibraryService) *GearLibraryHandler {
	return &GearLibraryHandler{svc: svc}
}

func (h *GearLibraryHandler) ListGearLibrary(w http.ResponseWriter, r *http.Request, params api.ListGearLibraryParams) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	includeArchived := false
	if params.IncludeArchived != nil {
		includeArchived = *params.IncludeArchived
	}

	items, err := h.svc.ListItems(r.Context(), userID, includeArchived)
	if err != nil {
		sendError(w, r, err)
		return
	}

	res := make([]api.GearLibraryItem, 0, len(items))
	for _, item := range items {
		res = append(res, mapping.ToGearLibraryItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

func (h *GearLibraryHandler) CreateGearLibraryItem(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GearLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelGearLibraryItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), userID, &modelReq)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToGearLibraryItemResponse(createdItem))
}

func (h *GearLibraryHandler) GetGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	item, err := h.svc.GetItem(r.Context(), itemId.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToGearLibraryItemResponse(item))
}

func (h *GearLibraryHandler) UpdateGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GearLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelGearLibraryItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), itemId.String(), userID, &modelReq)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToGearLibraryItemResponse(updatedItem))
}

func (h *GearLibraryHandler) DeleteGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.DeleteItem(r.Context(), itemId.String(), userID); err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *GearLibraryHandler) ReplaceAllGearLibraryItems(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllGearLibraryItemsJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []*model.GearLibraryItem
	for _, req := range reqBody {
		items = append(items, mapping.ToModelGearLibraryItemFromAPI(req))
	}

	if err := h.svc.ReplaceAllItems(r.Context(), userID, items); err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
