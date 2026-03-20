package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/handler/dto"
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

	res := make([]dto.TripMealItemResponse, 0, len(items))
	for _, item := range items {
		res = append(res, toTripMealItemResponse(item))
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

	sendJSON(w, http.StatusCreated, toTripMealItemResponse(createdItem))
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

	sendJSON(w, http.StatusOK, toTripMealItemResponse(updatedItem))
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

func toTripMealItemResponse(item *model.TripMealItem) dto.TripMealItemResponse {
	return dto.TripMealItemResponse{
		ID:            item.ID,
		TripID:        item.TripID,
		LibraryItemID: item.LibraryItemID,
		Day:           item.Day,
		MealType:      item.MealType,
		Name:          item.Name,
		Weight:        item.Weight,
		Calories:      item.Calories,
		Quantity:      item.Quantity,
		Note:          item.Note,
		CreatedAt:     item.CreatedAt,
		CreatedBy:     item.CreatedBy,
		UpdatedAt:     item.UpdatedAt,
		UpdatedBy:     item.UpdatedBy,
	}
}
