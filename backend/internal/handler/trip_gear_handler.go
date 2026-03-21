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

type TripGearHandler struct {
	svc *service.TripGearService
}

func NewTripGearHandler(svc *service.TripGearService) *TripGearHandler {
	return &TripGearHandler{svc: svc}
}

func (h *TripGearHandler) ListTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	items, err := h.svc.ListItems(r.Context(), tripId.String(), userID)
	if err != nil {
		sendError(w, err)
		return
	}

	res := make([]api.TripGearItem, 0, len(items))
	for _, item := range items {
		res = append(res, mapping.ToTripGearItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

func (h *TripGearHandler) AddTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.TripGearItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelTripGearItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), tripId.String(), userID, &modelReq)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToTripGearItemResponse(createdItem))
}

func (h *TripGearHandler) UpdateTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.TripGearItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelTripGearItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), tripId.String(), itemId.String(), userID, &modelReq)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToTripGearItemResponse(updatedItem))
}

func (h *TripGearHandler) RemoveTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.DeleteItem(r.Context(), tripId.String(), itemId.String(), userID); err != nil {
		sendError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *TripGearHandler) ReplaceAllTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllTripGearJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	var items []*model.TripGearItem
	for _, req := range reqBody {
		items = append(items, mapping.ToModelTripGearItemFromAPI(req))
	}

	if err := h.svc.ReplaceAllItems(r.Context(), tripId.String(), userID, items); err != nil {
		sendError(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
