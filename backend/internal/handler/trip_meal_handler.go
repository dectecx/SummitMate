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

type TripMealHandler struct {
	svc *service.TripMealService
}

func NewTripMealHandler(svc *service.TripMealService) *TripMealHandler {
	return &TripMealHandler{svc: svc}
}

func (h *TripMealHandler) ListTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
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

	res := make([]api.TripMealItem, 0, len(items))
	for _, item := range items {
		res = append(res, mapping.ToTripMealItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

func (h *TripMealHandler) AddTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.TripMealItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelTripMealItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), tripId.String(), userID, &modelReq)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToTripMealItemResponse(createdItem))
}

func (h *TripMealHandler) UpdateTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.TripMealItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	modelReq := mapping.ToModelTripMealItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), tripId.String(), itemId.String(), userID, &modelReq)
	if err != nil {
		sendError(w, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToTripMealItemResponse(updatedItem))
}

func (h *TripMealHandler) RemoveTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
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

func (h *TripMealHandler) ReplaceAllTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllTripMealsJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	var items []*model.TripMealItem
	for _, req := range reqBody {
		items = append(items, mapping.ToModelTripMealItemFromAPI(req))
	}

	if err := h.svc.ReplaceAllItems(r.Context(), tripId.String(), userID, items); err != nil {
		sendError(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
