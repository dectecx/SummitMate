package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
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
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	messages, err := h.service.ListTripMessages(r.Context(), tripID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	resp := make([]api.Message, len(messages))
	for i, m := range messages {
		resp[i] = mapping.ToMessageResponse(m)
	}
	sendJSON(w, http.StatusOK, resp)
}

func (h *MessageHandler) AddTripMessage(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.MessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
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
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToMessageResponse(created))
}

func (h *MessageHandler) UpdateTripMessage(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, messageID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.MessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
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
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToMessageResponse(updated))
}

func (h *MessageHandler) DeleteTripMessage(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, messageID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.service.DeleteTripMessage(r.Context(), tripID.String(), messageID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
