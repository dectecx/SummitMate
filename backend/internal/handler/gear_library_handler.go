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

type GearLibraryHandler struct {
	svc *service.GearLibraryService
}

func NewGearLibraryHandler(svc *service.GearLibraryService) *GearLibraryHandler {
	return &GearLibraryHandler{svc: svc}
}

// ListGearLibrary 取得使用者的個人裝備庫列表
// (GET /gear-library)
func (h *GearLibraryHandler) ListGearLibrary(w http.ResponseWriter, r *http.Request, params api.ListGearLibraryParams) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	includeArchived := false
	if params.IncludeArchived != nil {
		includeArchived = *params.IncludeArchived
	}

	items, err := h.svc.ListItems(r.Context(), userID, includeArchived)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "查詢失敗: "+err.Error())
		return
	}

	var res []api.GearLibraryItem
	for _, item := range items {
		res = append(res, api.GearLibraryItem{
			Id:         toOpenAPIUUID(item.ID),
			UserId:     toOpenAPIUUID(item.UserID),
			Name:       item.Name,
			Weight:     item.Weight,
			Category:   item.Category,
			Notes:      item.Notes,
			IsArchived: item.IsArchived,
			CreatedAt:  toOpenAPITime(item.CreatedAt),
			UpdatedAt:  toOpenAPITime(item.UpdatedAt),
		})
	}
	if res == nil {
		res = []api.GearLibraryItem{}
	}

	sendJSON(w, http.StatusOK, res)
}

// CreateGearLibraryItem 新增個人裝備至庫中
// (POST /gear-library)
func (h *GearLibraryHandler) CreateGearLibraryItem(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.GearLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	modelReq := &model.GearLibraryItem{
		Name:       req.Name,
		Weight:     req.Weight,
		Category:   req.Category,
		Notes:      req.Notes,
		IsArchived: false,
	}
	if req.IsArchived != nil {
		modelReq.IsArchived = *req.IsArchived
	}

	createdItem, err := h.svc.CreateItem(r.Context(), userID, modelReq)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "建立失敗: "+err.Error())
		return
	}

	res := api.GearLibraryItem{
		Id:         toOpenAPIUUID(createdItem.ID),
		UserId:     toOpenAPIUUID(createdItem.UserID),
		Name:       createdItem.Name,
		Weight:     createdItem.Weight,
		Category:   createdItem.Category,
		Notes:      createdItem.Notes,
		IsArchived: createdItem.IsArchived,
		CreatedAt:  toOpenAPITime(createdItem.CreatedAt),
		UpdatedAt:  toOpenAPITime(createdItem.UpdatedAt),
	}
	sendJSON(w, http.StatusCreated, res)
}

// GetGearLibraryItem 取得單一裝備詳情
// (GET /gear-library/{itemId})
func (h *GearLibraryHandler) GetGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	item, err := h.svc.GetItem(r.Context(), itemId.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusNotFound, "找不到該裝備")
		return
	}

	res := api.GearLibraryItem{
		Id:         toOpenAPIUUID(item.ID),
		UserId:     toOpenAPIUUID(item.UserID),
		Name:       item.Name,
		Weight:     item.Weight,
		Category:   item.Category,
		Notes:      item.Notes,
		IsArchived: item.IsArchived,
		CreatedAt:  toOpenAPITime(item.CreatedAt),
		UpdatedAt:  toOpenAPITime(item.UpdatedAt),
	}
	sendJSON(w, http.StatusOK, res)
}

// UpdateGearLibraryItem 更新個人裝備資料
// (PUT /gear-library/{itemId})
func (h *GearLibraryHandler) UpdateGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.GearLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	modelReq := &model.GearLibraryItem{
		Name:       req.Name,
		Weight:     req.Weight,
		Category:   req.Category,
		Notes:      req.Notes,
		IsArchived: false,
	}
	if req.IsArchived != nil {
		modelReq.IsArchived = *req.IsArchived
	}

	updatedItem, err := h.svc.UpdateItem(r.Context(), itemId.String(), userID, modelReq)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "更新失敗: "+err.Error())
		return
	}

	res := api.GearLibraryItem{
		Id:         toOpenAPIUUID(updatedItem.ID),
		UserId:     toOpenAPIUUID(updatedItem.UserID),
		Name:       updatedItem.Name,
		Weight:     updatedItem.Weight,
		Category:   updatedItem.Category,
		Notes:      updatedItem.Notes,
		IsArchived: updatedItem.IsArchived,
		CreatedAt:  toOpenAPITime(updatedItem.CreatedAt),
		UpdatedAt:  toOpenAPITime(updatedItem.UpdatedAt),
	}
	sendJSON(w, http.StatusOK, res)
}

// DeleteGearLibraryItem 刪除個人裝備 (支援實體刪除)
// (DELETE /gear-library/{itemId})
func (h *GearLibraryHandler) DeleteGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	if err := h.svc.DeleteItem(r.Context(), itemId.String(), userID); err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "刪除失敗")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
