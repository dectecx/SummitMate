package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"summitmate/api"
	"summitmate/internal/handler/dto"
	appMiddleware "summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	"github.com/google/uuid"
)

type GroupEventHandler struct {
	service service.GroupEventService
}

func NewGroupEventHandler(service service.GroupEventService) *GroupEventHandler {
	return &GroupEventHandler{service: service}
}

func (h *GroupEventHandler) GetGroupEvents(w http.ResponseWriter, r *http.Request, params api.GetGroupEventsParams) {
	var statusPtr, creatorIDPtr *string
	if params.Status != nil {
		s := string(*params.Status)
		statusPtr = &s
	}
	if params.CreatorId != nil {
		c := params.CreatorId.String()
		creatorIDPtr = &c
	}

	events, err := h.service.ListEvents(r.Context(), statusPtr, creatorIDPtr)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to list events")
		return
	}

	resp := make([]dto.GroupEventResponse, len(events))
	for i, e := range events {
		resp[i] = toGroupEventResponse(e)
	}

	sendJSON(w, http.StatusOK, resp)
}

func (h *GroupEventHandler) PostGroupEvents(w http.ResponseWriter, r *http.Request) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req api.GroupEventRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	var endDate *time.Time
	if req.EndDate != nil {
		t := req.EndDate.Time
		endDate = &t
	}

	maxMembers := 0
	if req.MaxMembers != nil {
		maxMembers = *req.MaxMembers
	}

	approvalRequired := false
	if req.ApprovalRequired != nil {
		approvalRequired = *req.ApprovalRequired
	}

	privateMessage := ""
	if req.PrivateMessage != nil {
		privateMessage = *req.PrivateMessage
	}

	var linkedTripID *string
	if req.LinkedTripId != nil {
		s := req.LinkedTripId.String()
		linkedTripID = &s
	}

	event := &model.GroupEvent{
		Title:            req.Title,
		Description:      req.Description,
		Location:         req.Location,
		StartDate:        req.StartDate.Time,
		EndDate:          endDate,
		MaxMembers:       maxMembers,
		ApprovalRequired: approvalRequired,
		PrivateMessage:   privateMessage,
		LinkedTripID:     linkedTripID,
		CreatedBy:        userID,
		UpdatedBy:        userID,
	}

	if err := h.service.CreateEvent(r.Context(), event); err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to create event")
		return
	}

	sendJSON(w, http.StatusCreated, toGroupEventResponse(event))
}

func (h *GroupEventHandler) GetGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	event, err := h.service.GetEvent(r.Context(), id.String())
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to get event")
		return
	}
	if event == nil {
		sendErrorResponse(w, http.StatusNotFound, "Event not found")
		return
	}

	sendJSON(w, http.StatusOK, toGroupEventResponse(event))
}

func (h *GroupEventHandler) PatchGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req api.GroupEventRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	var endDate *time.Time
	if req.EndDate != nil {
		t := req.EndDate.Time
		endDate = &t
	}

	maxMembers := 0
	if req.MaxMembers != nil {
		maxMembers = *req.MaxMembers
	}

	approvalRequired := false
	if req.ApprovalRequired != nil {
		approvalRequired = *req.ApprovalRequired
	}

	privateMessage := ""
	if req.PrivateMessage != nil {
		privateMessage = *req.PrivateMessage
	}

	var linkedTripID *string
	if req.LinkedTripId != nil {
		s := req.LinkedTripId.String()
		linkedTripID = &s
	}

	event := &model.GroupEvent{
		ID:               id.String(),
		Title:            req.Title,
		Description:      req.Description,
		Location:         req.Location,
		StartDate:        req.StartDate.Time,
		EndDate:          endDate,
		MaxMembers:       maxMembers,
		ApprovalRequired: approvalRequired,
		PrivateMessage:   privateMessage,
		LinkedTripID:     linkedTripID,
		UpdatedBy:        userID,
	}

	if err := h.service.UpdateEvent(r.Context(), event, userID); err != nil {
		if err.Error() == "permission denied" {
			sendErrorResponse(w, http.StatusForbidden, err.Error())
			return
		}
		if err.Error() == "event not found" {
			sendErrorResponse(w, http.StatusNotFound, err.Error())
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to update event")
		return
	}

	sendJSON(w, http.StatusOK, toGroupEventResponse(event))
}

func (h *GroupEventHandler) DeleteGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	if err := h.service.DeleteEvent(r.Context(), id.String(), userID); err != nil {
		if err.Error() == "permission denied" {
			sendErrorResponse(w, http.StatusForbidden, err.Error())
			return
		}
		if err.Error() == "event not found" {
			sendErrorResponse(w, http.StatusNotFound, err.Error())
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to delete event")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *GroupEventHandler) PostGroupEventsIdApply(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req api.GroupEventApplicationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	app := &model.GroupEventApplication{
		EventID: id.String(),
		UserID:  userID,
		Message: req.Message,
	}

	if err := h.service.ApplyToEvent(r.Context(), app); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, err.Error())
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func (h *GroupEventHandler) GetGroupEventsIdApplications(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	apps, err := h.service.ListApplications(r.Context(), id.String(), userID)
	if err != nil {
		if err.Error() == "permission denied" {
			sendErrorResponse(w, http.StatusForbidden, err.Error())
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to list applications")
		return
	}

	resp := make([]dto.GroupEventApplicationResponse, len(apps))
	for i, a := range apps {
		resp[i] = toGroupEventApplicationResponse(a)
	}

	sendJSON(w, http.StatusOK, resp)
}

func (h *GroupEventHandler) PatchGroupEventsApplicationsAppId(w http.ResponseWriter, r *http.Request, appId uuid.UUID) {
	executorID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Status  string `json:"status"`
		EventID string `json:"event_id"`
		UserID  string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if err := h.service.ProcessApplication(r.Context(), req.EventID, req.UserID, req.Status, executorID); err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to process application")
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (h *GroupEventHandler) GetGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	comments, err := h.service.ListComments(r.Context(), id.String())
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to list comments")
		return
	}

	resp := make([]dto.GroupEventCommentResponse, len(comments))
	for i, c := range comments {
		resp[i] = toGroupEventCommentResponse(c)
	}

	sendJSON(w, http.StatusOK, resp)
}

func (h *GroupEventHandler) PostGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req api.GroupEventCommentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	comment := &model.GroupEventComment{
		EventID: id.String(),
		UserID:  userID,
		Content: req.Content,
	}

	if err := h.service.AddComment(r.Context(), comment); err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to add comment")
		return
	}

	sendJSON(w, http.StatusCreated, toGroupEventCommentResponse(comment))
}

func (h *GroupEventHandler) DeleteGroupEventsCommentsCommentId(w http.ResponseWriter, r *http.Request, commentId uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	if err := h.service.DeleteComment(r.Context(), commentId.String(), userID); err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to delete comment")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *GroupEventHandler) PostGroupEventsIdLike(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	isLiked, err := h.service.ToggleLike(r.Context(), id.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to toggle like")
		return
	}

	sendJSON(w, http.StatusOK, map[string]bool{"is_liked": isLiked})
}

// Converters

func toGroupEventResponse(e *model.GroupEvent) dto.GroupEventResponse {
	resp := dto.GroupEventResponse{
		ID:               e.ID,
		Title:            e.Title,
		Description:      e.Description,
		Location:         e.Location,
		StartDate:        e.StartDate.Format("2006-01-02"),
		Status:           e.Status,
		MaxMembers:       e.MaxMembers,
		ApprovalRequired: e.ApprovalRequired,
		PrivateMessage:   e.PrivateMessage,
		LinkedTripID:     e.LinkedTripID,
		LikeCount:        e.LikeCount,
		CommentCount:     e.CommentCount,
		CreatedAt:        e.CreatedAt,
		CreatedBy:        e.CreatedBy,
		UpdatedAt:        e.UpdatedAt,
		UpdatedBy:        e.UpdatedBy,
	}
	if e.EndDate != nil {
		s := e.EndDate.Format("2006-01-02")
		resp.EndDate = &s
	}
	return resp
}

func toGroupEventApplicationResponse(a *model.GroupEventApplication) dto.GroupEventApplicationResponse {
	return dto.GroupEventApplicationResponse{
		ID:        a.ID,
		EventID:   a.EventID,
		UserID:    a.UserID,
		Status:    a.Status,
		Message:   a.Message,
		CreatedAt: a.CreatedAt,
		CreatedBy: a.CreatedBy,
		UpdatedAt: a.UpdatedAt,
		UpdatedBy: a.UpdatedBy,
	}
}

func toGroupEventCommentResponse(c *model.GroupEventComment) dto.GroupEventCommentResponse {
	return dto.GroupEventCommentResponse{
		ID:          c.ID,
		EventID:     c.EventID,
		UserID:      c.UserID,
		Content:     c.Content,
		DisplayName: c.DisplayName,
		Avatar:      c.Avatar,
		CreatedAt:   c.CreatedAt,
		CreatedBy:   c.CreatedBy,
		UpdatedAt:   c.UpdatedAt,
		UpdatedBy:   c.UpdatedBy,
	}
}
