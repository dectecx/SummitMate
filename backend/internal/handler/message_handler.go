package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"summitmate/api"
	"summitmate/internal/handler/dto"
	"summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type MessageHandler struct {
	service *service.MessageService
}

func NewMessageHandler(service *service.MessageService) *MessageHandler {
	return &MessageHandler{service: service}
}

func (h *MessageHandler) ListTripMessages(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	messages, err := h.service.ListTripMessages(r.Context(), tripID.String(), userID)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限存取該行程留言")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "無法取得留言")
		return
	}

	resp := make([]dto.MessageResponse, len(messages))
	for i, m := range messages {
		resp[i] = toMessageResponse(m)
	}
	sendJSON(w, http.StatusOK, resp)
}

func (h *MessageHandler) AddTripMessage(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.MessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
		return
	}

	category := ""
	if req.Category != nil {
		category = *req.Category
	}

	var parentIDStr *string
	if req.ParentId != nil {
		s := req.ParentId.String()
		parentIDStr = &s
	}

	msg := &model.TripMessage{
		Category:  category,
		Content:   req.Content,
		Timestamp: time.Now(),
		ParentID:  parentIDStr,
	}

	created, err := h.service.AddTripMessage(r.Context(), tripID.String(), userID, msg)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限新增留言")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "新增留言失敗")
		return
	}

	sendJSON(w, http.StatusCreated, toMessageResponse(created))
}

func (h *MessageHandler) UpdateTripMessage(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, messageID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.MessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
		return
	}

	category := ""
	if req.Category != nil {
		category = *req.Category
	}

	msg := &model.TripMessage{
		Category: category,
		Content:  req.Content,
	}

	updated, err := h.service.UpdateTripMessage(r.Context(), tripID.String(), messageID.String(), userID, msg)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限編輯此留言")
			return
		}
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到該留言")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "更新留言失敗")
		return
	}

	sendJSON(w, http.StatusOK, toMessageResponse(updated))
}

func (h *MessageHandler) DeleteTripMessage(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, messageID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	err := h.service.DeleteTripMessage(r.Context(), tripID.String(), messageID.String(), userID)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限刪除此留言")
			return
		}
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到該留言")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "刪除留言失敗")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func toMessageResponse(m *model.TripMessage) dto.MessageResponse {
	var replies []dto.MessageResponse
	if len(m.Replies) > 0 {
		replies = make([]dto.MessageResponse, len(m.Replies))
		for i, rp := range m.Replies {
			replies[i] = toMessageResponse(rp) // Recursive mapping
		}
	} else {
		replies = []dto.MessageResponse{}
	}

	return dto.MessageResponse{
		ID:          m.ID,
		TripID:      m.TripID,
		ParentID:    m.ParentID,
		UserID:      m.UserID,
		DisplayName: m.DisplayName,
		Avatar:      m.Avatar,
		Category:    m.Category,
		Content:     m.Content,
		Timestamp:   m.Timestamp,
		Replies:     replies,
		CreatedAt:   m.CreatedAt,
		CreatedBy:   m.CreatedBy,
		UpdatedAt:   m.UpdatedAt,
		UpdatedBy:   m.UpdatedBy,
	}
}
