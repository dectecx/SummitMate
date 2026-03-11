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

	var res []api.TripGearItem
	for _, item := range items {
		var libIDStr *string
		if item.LibraryItemID != nil {
			s := *item.LibraryItemID
			libIDStr = &s
		}
		res = append(res, api.TripGearItem{
			Id:            toOpenAPIUUID(item.ID),
			TripId:        toOpenAPIUUID(item.TripID),
			LibraryItemId: toOpenAPIUUIDPtr(libIDStr),
			Name:          item.Name,
			Weight:        item.Weight,
			Category:      item.Category,
			Quantity:      item.Quantity,
			IsChecked:     item.IsChecked,
			OrderIndex:    item.OrderIndex,
			CreatedAt:     toOpenAPITime(item.CreatedAt),
			UpdatedAt:     toOpenAPITime(item.UpdatedAt),
		})
	}
	if res == nil {
		res = []api.TripGearItem{}
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

	var resLibIDStr *string
	if createdItem.LibraryItemID != nil {
		s := *createdItem.LibraryItemID
		resLibIDStr = &s
	}

	res := api.TripGearItem{
		Id:            toOpenAPIUUID(createdItem.ID),
		TripId:        toOpenAPIUUID(createdItem.TripID),
		LibraryItemId: toOpenAPIUUIDPtr(resLibIDStr),
		Name:          createdItem.Name,
		Weight:        createdItem.Weight,
		Category:      createdItem.Category,
		Quantity:      createdItem.Quantity,
		IsChecked:     createdItem.IsChecked,
		OrderIndex:    createdItem.OrderIndex,
		CreatedAt:     toOpenAPITime(createdItem.CreatedAt),
		UpdatedAt:     toOpenAPITime(createdItem.UpdatedAt),
	}
	sendJSON(w, http.StatusCreated, res)
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

	var resLibIDStr *string
	if updatedItem.LibraryItemID != nil {
		s := *updatedItem.LibraryItemID
		resLibIDStr = &s
	}

	res := api.TripGearItem{
		Id:            toOpenAPIUUID(updatedItem.ID),
		TripId:        toOpenAPIUUID(updatedItem.TripID),
		LibraryItemId: toOpenAPIUUIDPtr(resLibIDStr),
		Name:          updatedItem.Name,
		Weight:        updatedItem.Weight,
		Category:      updatedItem.Category,
		Quantity:      updatedItem.Quantity,
		IsChecked:     updatedItem.IsChecked,
		OrderIndex:    updatedItem.OrderIndex,
		CreatedAt:     toOpenAPITime(updatedItem.CreatedAt),
		UpdatedAt:     toOpenAPITime(updatedItem.UpdatedAt),
	}
	sendJSON(w, http.StatusOK, res)
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

func toOpenAPIUUIDPtr(s *string) *openapi_types.UUID {
	if s == nil {
		return nil
	}
	u := toOpenAPIUUID(*s)
	return &u
}
