package library

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type LibraryHandler struct {
	gearSvc GearLibraryService
	mealSvc MealLibraryService
}

func NewLibraryHandler(gearSvc GearLibraryService, mealSvc MealLibraryService) *LibraryHandler {
	return &LibraryHandler{
		gearSvc: gearSvc,
		mealSvc: mealSvc,
	}
}

// Gear Library Handlers

func (h *LibraryHandler) ListGearLibrary(w http.ResponseWriter, r *http.Request, params api.ListGearLibraryParams) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	includeArchived := false
	if params.IncludeArchived != nil {
		includeArchived = *params.IncludeArchived
	}

	items, err := h.gearSvc.ListItems(r.Context(), userID, includeArchived)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	res := make([]api.GearLibraryItem, 0, len(items))
	for _, item := range items {
		res = append(res, ToGearLibraryItemResponse(item))
	}

	apiutil.SendJSON(w, http.StatusOK, res)
}

func (h *LibraryHandler) CreateGearLibraryItem(w http.ResponseWriter, r *http.Request) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GearLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelGearLibraryItem(req)

	createdItem, err := h.gearSvc.CreateItem(r.Context(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToGearLibraryItemResponse(createdItem))
}

func (h *LibraryHandler) GetGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	item, err := h.gearSvc.GetItem(r.Context(), itemId.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToGearLibraryItemResponse(item))
}

func (h *LibraryHandler) UpdateGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GearLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelGearLibraryItem(req)

	updatedItem, err := h.gearSvc.UpdateItem(r.Context(), itemId.String(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToGearLibraryItemResponse(updatedItem))
}

func (h *LibraryHandler) DeleteGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.gearSvc.DeleteItem(r.Context(), itemId.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *LibraryHandler) ReplaceAllGearLibraryItems(w http.ResponseWriter, r *http.Request) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllGearLibraryItemsJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []*GearLibraryItem
	for _, req := range reqBody {
		items = append(items, ToModelGearLibraryItemFromAPI(req))
	}

	if err := h.gearSvc.ReplaceAllItems(r.Context(), userID, items); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// Meal Library Handlers

func (h *LibraryHandler) ListMealLibrary(w http.ResponseWriter, r *http.Request, params api.ListMealLibraryParams) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	includeArchived := false
	if params.IncludeArchived != nil {
		includeArchived = *params.IncludeArchived
	}

	items, err := h.mealSvc.ListItems(r.Context(), userID, includeArchived)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	res := make([]api.MealLibraryItem, 0, len(items))
	for _, item := range items {
		res = append(res, ToMealLibraryItemResponse(item))
	}

	apiutil.SendJSON(w, http.StatusOK, res)
}

func (h *LibraryHandler) CreateMealLibraryItem(w http.ResponseWriter, r *http.Request) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.MealLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelMealLibraryItem(req)

	createdItem, err := h.mealSvc.CreateItem(r.Context(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToMealLibraryItemResponse(createdItem))
}

func (h *LibraryHandler) GetMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	item, err := h.mealSvc.GetItem(r.Context(), itemId.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToMealLibraryItemResponse(item))
}

func (h *LibraryHandler) UpdateMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.MealLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	modelReq := ToModelMealLibraryItem(req)

	updatedItem, err := h.mealSvc.UpdateItem(r.Context(), itemId.String(), userID, &modelReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToMealLibraryItemResponse(updatedItem))
}

func (h *LibraryHandler) DeleteMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.mealSvc.DeleteItem(r.Context(), itemId.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *LibraryHandler) ReplaceAllMealLibraryItems(w http.ResponseWriter, r *http.Request) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var reqBody api.ReplaceAllMealLibraryItemsJSONBody
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	var items []*MealLibraryItem
	for _, req := range reqBody {
		items = append(items, ToModelMealLibraryItemFromAPI(req))
	}

	if err := h.mealSvc.ReplaceAllItems(r.Context(), userID, items); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
