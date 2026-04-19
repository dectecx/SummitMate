package trip

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	"summitmate/internal/middleware"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type TripGearHandler struct {
	svc TripGearService
}

func NewTripGearHandler(svc TripGearService) *TripGearHandler {
	return &TripGearHandler{svc: svc}
}

func (h *TripGearHandler) ListTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	items, err := h.svc.ListItems(r.Context(), tripId.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	res := make([]api.TripGearItem, 0, len(items))
	for _, item := range items {
		res = append(res, ToTripGearItemResponse(item))
	}

	apiutil.SendJSON(w, http.StatusOK, res)
}

func (h *TripGearHandler) AddTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripGearItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelTripGearItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), tripId.String(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToTripGearItemResponse(createdItem))
}

func (h *TripGearHandler) UpdateTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripGearItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelTripGearItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), tripId.String(), itemId.String(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToTripGearItemResponse(updatedItem))
}

func (h *TripGearHandler) RemoveTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.DeleteItem(r.Context(), tripId.String(), itemId.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *TripGearHandler) ReplaceAllTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllTripGearJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []*TripGearItem
	for _, req := range reqBody {
		items = append(items, ToModelTripGearItemFromAPI(req))
	}

	if err := h.svc.ReplaceAllItems(r.Context(), tripId.String(), userID, items); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
