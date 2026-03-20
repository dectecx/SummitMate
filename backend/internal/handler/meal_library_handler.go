package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type MealLibraryHandler struct {
	svc *service.MealLibraryService
}

func NewMealLibraryHandler(svc *service.MealLibraryService) *MealLibraryHandler {
	return &MealLibraryHandler{svc: svc}
}

// ListMealLibrary 取得使用者的個人食物庫列表
// (GET /meal-library)
func (h *MealLibraryHandler) ListMealLibrary(w http.ResponseWriter, r *http.Request, params api.ListMealLibraryParams) {
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

	res := make([]api.MealLibraryItem, 0, len(items))
	for _, item := range items {
		res = append(res, mapping.ToMealLibraryItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

// CreateMealLibraryItem 新增個人食物至庫中
// (POST /meal-library)
func (h *MealLibraryHandler) CreateMealLibraryItem(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.MealLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	modelReq := mapping.ToModelMealLibraryItem(req)

	createdItem, err := h.svc.CreateItem(r.Context(), userID, &modelReq)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "建立失敗: "+err.Error())
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToMealLibraryItemResponse(createdItem))
}

// GetMealLibraryItem 取得單一食物詳情
// (GET /meal-library/{itemId})
func (h *MealLibraryHandler) GetMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	item, err := h.svc.GetItem(r.Context(), itemId.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusNotFound, "找不到該食物")
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToMealLibraryItemResponse(item))
}

// UpdateMealLibraryItem 更新個人食物資料
// (PUT /meal-library/{itemId})
func (h *MealLibraryHandler) UpdateMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.MealLibraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	modelReq := mapping.ToModelMealLibraryItem(req)

	updatedItem, err := h.svc.UpdateItem(r.Context(), itemId.String(), userID, &modelReq)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "更新失敗: "+err.Error())
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToMealLibraryItemResponse(updatedItem))
}

// DeleteMealLibraryItem 刪除個人食物
// (DELETE /meal-library/{itemId})
func (h *MealLibraryHandler) DeleteMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
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
