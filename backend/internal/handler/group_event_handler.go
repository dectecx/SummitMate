package handler

import (
	"encoding/json"
	"net/http"
	appMiddleware "summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	"summitmate/api"

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

	apiEvents := make([]interface{}, len(events))
	for i, e := range events {
		apiEvents[i] = mapToAPIGroupEvent(e)
	}

	sendJSON(w, http.StatusOK, apiEvents)
}

func (h *GroupEventHandler) PostGroupEvents(w http.ResponseWriter, r *http.Request) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Title            string  `json:"title"`
		Description      string  `json:"description"`
		Location         string  `json:"location"`
		StartDate        string  `json:"start_date"`
		EndDate          *string `json:"end_date"`
		MaxMembers       int     `json:"max_members"`
		ApprovalRequired bool    `json:"approval_required"`
		PrivateMessage   string  `json:"private_message"`
		LinkedTripID     *string `json:"linked_trip_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	startDate, _ := toServiceDate(req.StartDate)
	endDate := toServiceDatePtr(req.EndDate)

	event := &model.GroupEvent{
		Title:            req.Title,
		Description:      req.Description,
		Location:         req.Location,
		StartDate:        startDate,
		EndDate:          endDate,
		MaxMembers:       req.MaxMembers,
		ApprovalRequired: req.ApprovalRequired,
		PrivateMessage:   req.PrivateMessage,
		LinkedTripID:     req.LinkedTripID,
		CreatedBy:        userID,
		UpdatedBy:        userID,
	}

	if err := h.service.CreateEvent(r.Context(), event); err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "Failed to create event")
		return
	}

	sendJSON(w, http.StatusCreated, mapToAPIGroupEvent(event))
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

	sendJSON(w, http.StatusOK, mapToAPIGroupEvent(event))
}

func (h *GroupEventHandler) PatchGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Title            string  `json:"title"`
		Description      string  `json:"description"`
		Location         string  `json:"location"`
		StartDate        string  `json:"start_date"`
		EndDate          *string `json:"end_date"`
		MaxMembers       int     `json:"max_members"`
		ApprovalRequired bool    `json:"approval_required"`
		PrivateMessage   string  `json:"private_message"`
		LinkedTripID     *string `json:"linked_trip_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	startDate, _ := toServiceDate(req.StartDate)
	endDate := toServiceDatePtr(req.EndDate)

	event := &model.GroupEvent{
		ID:               id.String(),
		Title:            req.Title,
		Description:      req.Description,
		Location:         req.Location,
		StartDate:        startDate,
		EndDate:          endDate,
		MaxMembers:       req.MaxMembers,
		ApprovalRequired: req.ApprovalRequired,
		PrivateMessage:   req.PrivateMessage,
		LinkedTripID:     req.LinkedTripID,
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

	sendJSON(w, http.StatusOK, mapToAPIGroupEvent(event))
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

	var req struct {
		Message string `json:"message"`
	}
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

	apiApps := make([]interface{}, len(apps))
	for i, a := range apps {
		apiApps[i] = mapToAPIApplication(a)
	}

	sendJSON(w, http.StatusOK, apiApps)
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

	apiComments := make([]interface{}, len(comments))
	for i, c := range comments {
		apiComments[i] = mapToAPIComment(c)
	}

	sendJSON(w, http.StatusOK, apiComments)
}

func (h *GroupEventHandler) PostGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Content string `json:"content"`
	}
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

	sendJSON(w, http.StatusCreated, mapToAPIComment(comment))
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

// Helpers
func mapToAPIGroupEvent(e *model.GroupEvent) interface{} {
	return map[string]interface{}{
		"id":                e.ID,
		"title":             e.Title,
		"description":       e.Description,
		"location":          e.Location,
		"start_date":        toOpenAPIDate(e.StartDate),
		"end_date":          toOpenAPIDatePtr(e.EndDate),
		"status":            e.Status,
		"max_members":       e.MaxMembers,
		"approval_required": e.ApprovalRequired,
		"private_message":   e.PrivateMessage,
		"linked_trip_id":    toOpenAPIUUIDPtr(e.LinkedTripID),
		"like_count":        e.LikeCount,
		"comment_count":     e.CommentCount,
		"created_at":        toOpenAPITime(e.CreatedAt),
		"created_by":        toOpenAPIUUID(e.CreatedBy),
		"updated_at":        toOpenAPITime(e.UpdatedAt),
		"updated_by":        toOpenAPIUUID(e.UpdatedBy),
	}
}

func mapToAPIApplication(a *model.GroupEventApplication) interface{} {
	return map[string]interface{}{
		"id":         a.ID,
		"event_id":   toOpenAPIUUID(a.EventID),
		"user_id":    toOpenAPIUUID(a.UserID),
		"status":     a.Status,
		"message":    a.Message,
		"created_at": toOpenAPITime(a.CreatedAt),
		"created_by": toOpenAPIUUID(a.CreatedBy),
		"updated_at": toOpenAPITime(a.UpdatedAt),
		"updated_by": toOpenAPIUUID(a.UpdatedBy),
	}
}

func mapToAPIComment(c *model.GroupEventComment) interface{} {
	return map[string]interface{}{
		"id":           c.ID,
		"event_id":     toOpenAPIUUID(c.EventID),
		"user_id":      toOpenAPIUUID(c.UserID),
		"content":      c.Content,
		"display_name": c.DisplayName,
		"avatar":       c.Avatar,
		"created_at":   toOpenAPITime(c.CreatedAt),
		"created_by":   toOpenAPIUUID(c.CreatedBy),
		"updated_at":   toOpenAPITime(c.UpdatedAt),
		"updated_by":   toOpenAPIUUID(c.UpdatedBy),
	}
}
