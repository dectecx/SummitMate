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

type TripMealHandler struct {
	svc TripMealService
}

func NewTripMealHandler(svc TripMealService) *TripMealHandler {
	return &TripMealHandler{svc: svc}
}

func (h *TripMealHandler) ListTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
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

	res := make([]api.TripMealItem, 0, len(items))
	for _, item := range items {
		res = append(res, ToTripMealItemResponse(item))
	}

	apiutil.SendJSON(w, http.StatusOK, res)
}

func (h *TripMealHandler) AddTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripMealItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelTripMealItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), tripId.String(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToTripMealItemResponse(createdItem))
}

func (h *TripMealHandler) UpdateTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripMealItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelTripMealItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), tripId.String(), itemId.String(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToTripMealItemResponse(updatedItem))
}

func (h *TripMealHandler) RemoveTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
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

func (h *TripMealHandler) ReplaceAllTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllTripMealsJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []*TripMealItem
	for _, req := range reqBody {
		items = append(items, ToModelTripMealItemFromAPI(req))
	}

	if err := h.svc.ReplaceAllItems(r.Context(), tripId.String(), userID, items); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
