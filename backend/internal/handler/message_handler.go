package handler

import (
	"encoding/json"
	"net/http"
	"time"

	openapi_types "github.com/oapi-codegen/runtime/types"
	"summitmate/api"
	"summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"
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

	resp := make([]api.Message, len(messages))
	for i, m := range messages {
		resp[i] = mapToAPIMessage(m)
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

	msg := &model.TripMessage{
		Category:  category,
		Content:   req.Content,
		Timestamp: time.Now(),
	}
	if req.ParentId != nil {
		parentIDStr := req.ParentId.String()
		msg.ParentID = &parentIDStr
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

	sendJSON(w, http.StatusCreated, mapToAPIMessage(created))
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

	sendJSON(w, http.StatusOK, mapToAPIMessage(updated))
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

func mapToAPIMessage(m *model.TripMessage) api.Message {
	id := toOpenAPIUUID(m.ID)
	tripID := toOpenAPIUUID(m.TripID)
	userID := toOpenAPIUUID(m.UserID)

	var parentID *openapi_types.UUID
	if m.ParentID != nil {
		pid := toOpenAPIUUID(*m.ParentID)
		parentID = &pid
	}

	var replies []api.Message
	if len(m.Replies) > 0 {
		replies = make([]api.Message, len(m.Replies))
		for i, rp := range m.Replies {
			replies[i] = mapToAPIMessage(rp) // Recursive mapping
		}
	} else {
		replies = []api.Message{}
	}

	createdAt := toOpenAPITime(m.CreatedAt)
	updatedAt := toOpenAPITime(m.UpdatedAt)

	return api.Message{
		Id:          id,
		TripId:      tripID,
		ParentId:    parentID,
		UserId:      userID,
		DisplayName: m.DisplayName,
		Avatar:      &m.Avatar,
		Category:    m.Category,
		Content:     m.Content,
		Timestamp:   toOpenAPITime(m.Timestamp),
		Replies:     &replies, // Pointer to array needed for OpenAPI
		CreatedAt:   createdAt,
		UpdatedAt:   &updatedAt,
	}
}
