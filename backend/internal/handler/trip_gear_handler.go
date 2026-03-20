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

type TripGearHandler struct {
	svc *service.TripGearService
}

func NewTripGearHandler(svc *service.TripGearService) *TripGearHandler {
	return &TripGearHandler{svc: svc}
}

// ListTripGear 取得該行程的所有裝備
// (GET /trips/{tripId}/gear)
func (h *TripGearHandler) ListTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
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

	res := make([]dto.TripGearItemResponse, 0, len(items))
	for _, item := range items {
		res = append(res, toTripGearItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

// AddTripGear 將裝備加入至該行程
// (POST /trips/{tripId}/gear)
func (h *TripGearHandler) AddTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.TripGearItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	var libIDStr *string
	if req.LibraryItemId != nil {
		s := req.LibraryItemId.String()
		libIDStr = &s
	}

	modelReq := &model.TripGearItem{
		LibraryItemID: libIDStr,
		Name:          req.Name,
		Weight:        req.Weight,
		Category:      req.Category,
		Quantity:      *req.Quantity,
		IsChecked:     *req.IsChecked,
		OrderIndex:    req.OrderIndex,
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

	sendJSON(w, http.StatusCreated, toTripGearItemResponse(createdItem))
}

// UpdateTripGear 更新行程中的裝備
// (PUT /trips/{tripId}/gear/{itemId})
func (h *TripGearHandler) UpdateTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.TripGearItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	var libIDStr *string
	if req.LibraryItemId != nil {
		s := req.LibraryItemId.String()
		libIDStr = &s
	}

	modelReq := &model.TripGearItem{
		LibraryItemID: libIDStr,
		Name:          req.Name,
		Weight:        req.Weight,
		Category:      req.Category,
		Quantity:      *req.Quantity,
		IsChecked:     *req.IsChecked,
		OrderIndex:    req.OrderIndex,
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

	sendJSON(w, http.StatusOK, toTripGearItemResponse(updatedItem))
}

// RemoveTripGear 將裝備從行程中移除
// (DELETE /trips/{tripId}/gear/{itemId})
func (h *TripGearHandler) RemoveTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
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

func toTripGearItemResponse(item *model.TripGearItem) dto.TripGearItemResponse {
	return dto.TripGearItemResponse{
		ID:            item.ID,
		TripID:        item.TripID,
		LibraryItemID: item.LibraryItemID,
		Name:          item.Name,
		Weight:        item.Weight,
		Category:      item.Category,
		Quantity:      item.Quantity,
		IsChecked:     item.IsChecked,
		OrderIndex:    item.OrderIndex,
		CreatedAt:     item.CreatedAt,
		CreatedBy:     item.CreatedBy,
		UpdatedAt:     item.UpdatedAt,
		UpdatedBy:     item.UpdatedBy,
	}
}
