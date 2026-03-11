package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
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

// ListTripMeals 取得該行程的所有食物
// (GET /trips/{tripId}/meals)
func (h *TripMealHandler) ListTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	items, err := h.svc.ListItems(r.Context(), tripId.String(), userID)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限存取該行程")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "查詢失敗: "+err.Error())
		return
	}

	var res []api.TripMealItem
	for _, item := range items {
		var libIDStr *string
		if item.LibraryItemID != nil {
			s := *item.LibraryItemID
			libIDStr = &s
		}
		res = append(res, api.TripMealItem{
			Id:            toOpenAPIUUID(item.ID),
			TripId:        toOpenAPIUUID(item.TripID),
			LibraryItemId: toOpenAPIUUIDPtr(libIDStr),
			Day:           item.Day,
			MealType:      item.MealType,
			Name:          item.Name,
			Weight:        item.Weight,
			Calories:      item.Calories,
			Quantity:      item.Quantity,
			Note:          item.Note,
			CreatedAt:     toOpenAPITime(item.CreatedAt),
			UpdatedAt:     toOpenAPITime(item.UpdatedAt),
		})
	}
	if res == nil {
		res = []api.TripMealItem{}
	}

	sendJSON(w, http.StatusOK, res)
}

// AddTripMeal 將食物加入至該行程
// (POST /trips/{tripId}/meals)
func (h *TripMealHandler) AddTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.TripMealItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	var libIDStr *string
	if req.LibraryItemId != nil {
		s := req.LibraryItemId.String()
		libIDStr = &s
	}

	modelReq := &model.TripMealItem{
		LibraryItemID: libIDStr,
		Day:           req.Day,
		MealType:      req.MealType,
		Name:          req.Name,
		Weight:        req.Weight,
		Calories:      req.Calories,
		Quantity:      *req.Quantity,
		Note:          req.Note,
	}

	createdItem, err := h.svc.CreateItem(r.Context(), tripId.String(), userID, modelReq)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限存取該行程")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "建立失敗: "+err.Error())
		return
	}

	var resLibIDStr *string
	if createdItem.LibraryItemID != nil {
		s := *createdItem.LibraryItemID
		resLibIDStr = &s
	}

	res := api.TripMealItem{
		Id:            toOpenAPIUUID(createdItem.ID),
		TripId:        toOpenAPIUUID(createdItem.TripID),
		LibraryItemId: toOpenAPIUUIDPtr(resLibIDStr),
		Day:           createdItem.Day,
		MealType:      createdItem.MealType,
		Name:          createdItem.Name,
		Weight:        createdItem.Weight,
		Calories:      createdItem.Calories,
		Quantity:      createdItem.Quantity,
		Note:          createdItem.Note,
		CreatedAt:     toOpenAPITime(createdItem.CreatedAt),
		UpdatedAt:     toOpenAPITime(createdItem.UpdatedAt),
	}
	sendJSON(w, http.StatusCreated, res)
}

// UpdateTripMeal 更新行程中的食物
// (PUT /trips/{tripId}/meals/{itemId})
func (h *TripMealHandler) UpdateTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.TripMealItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	var libIDStr *string
	if req.LibraryItemId != nil {
		s := req.LibraryItemId.String()
		libIDStr = &s
	}

	modelReq := &model.TripMealItem{
		LibraryItemID: libIDStr,
		Day:           req.Day,
		MealType:      req.MealType,
		Name:          req.Name,
		Weight:        req.Weight,
		Calories:      req.Calories,
		Quantity:      *req.Quantity,
		Note:          req.Note,
	}

	updatedItem, err := h.svc.UpdateItem(r.Context(), tripId.String(), itemId.String(), userID, modelReq)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限存取該行程")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "更新失敗: "+err.Error())
		return
	}

	var resLibIDStr *string
	if updatedItem.LibraryItemID != nil {
		s := *updatedItem.LibraryItemID
		resLibIDStr = &s
	}

	res := api.TripMealItem{
		Id:            toOpenAPIUUID(updatedItem.ID),
		TripId:        toOpenAPIUUID(updatedItem.TripID),
		LibraryItemId: toOpenAPIUUIDPtr(resLibIDStr),
		Day:           updatedItem.Day,
		MealType:      updatedItem.MealType,
		Name:          updatedItem.Name,
		Weight:        updatedItem.Weight,
		Calories:      updatedItem.Calories,
		Quantity:      updatedItem.Quantity,
		Note:          updatedItem.Note,
		CreatedAt:     toOpenAPITime(updatedItem.CreatedAt),
		UpdatedAt:     toOpenAPITime(updatedItem.UpdatedAt),
	}
	sendJSON(w, http.StatusOK, res)
}

// RemoveTripMeal 將食物從行程中移除
// (DELETE /trips/{tripId}/meals/{itemId})
func (h *TripMealHandler) RemoveTripMeal(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	if err := h.svc.DeleteItem(r.Context(), tripId.String(), itemId.String(), userID); err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限存取該行程")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "刪除失敗")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
