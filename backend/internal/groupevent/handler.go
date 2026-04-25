package groupevent

import (
	"encoding/json"
	"net/http"
	"time"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	appMiddleware "summitmate/internal/middleware"

	"github.com/google/uuid"
)

type GroupEventHandler struct {
	service GroupEventService
}

func NewGroupEventHandler(service GroupEventService) *GroupEventHandler {
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

	page := 1
	if params.Page != nil {
		page = *params.Page
	}
	limit := 20
	if params.Limit != nil {
		limit = *params.Limit
	}
	search := ""
	if params.Search != nil {
		search = *params.Search
	}

	events, total, hasMore, err := h.service.ListEvents(r.Context(), statusPtr, creatorIDPtr, page, limit, search)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	items := make([]api.GroupEvent, len(events))
	for i, e := range events {
		items[i] = ToGroupEventResponse(e)
	}

	resp := api.GroupEventPaginationResponse{
		Items: items,
		Pagination: api.PaginationMetadata{
			HasMore: hasMore,
			Page:    page,
			Limit:   limit,
			Total:   total,
		},
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

func (h *GroupEventHandler) PostGroupEvents(w http.ResponseWriter, r *http.Request) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GroupEventRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
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

	event := &GroupEvent{
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
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToGroupEventResponse(event))
}

func (h *GroupEventHandler) GetGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	event, err := h.service.GetEvent(r.Context(), id.String())
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}
	if event == nil {
		apiutil.SendError(w, r, apperror.ErrEventNotFound)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToGroupEventResponse(event))
}

func (h *GroupEventHandler) PatchGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GroupEventRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
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

	event := &GroupEvent{
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
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToGroupEventResponse(event))
}

func (h *GroupEventHandler) DeleteGroupEventsId(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.service.DeleteEvent(r.Context(), id.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *GroupEventHandler) PostGroupEventsIdApply(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GroupEventApplicationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	app := &GroupEventApplication{
		EventID: id.String(),
		UserID:  userID,
		Message: req.Message,
	}

	if err := h.service.ApplyToEvent(r.Context(), app); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func (h *GroupEventHandler) GetGroupEventsIdApplications(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	apps, err := h.service.ListApplications(r.Context(), id.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	resp := make([]api.GroupEventApplication, len(apps))
	for i, a := range apps {
		resp[i] = ToGroupEventApplicationResponse(a)
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

func (h *GroupEventHandler) PatchGroupEventsApplicationsAppId(w http.ResponseWriter, r *http.Request, appId uuid.UUID) {
	executorID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req struct {
		Status  string `json:"status"`
		EventID string `json:"event_id"`
		UserID  string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	if err := h.service.ProcessApplication(r.Context(), req.EventID, req.UserID, req.Status, executorID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (h *GroupEventHandler) GetGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	comments, err := h.service.ListComments(r.Context(), id.String())
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	resp := make([]api.GroupEventComment, len(comments))
	for i, c := range comments {
		resp[i] = ToGroupEventCommentResponse(c)
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

func (h *GroupEventHandler) PostGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GroupEventCommentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	comment := &GroupEventComment{
		EventID: id.String(),
		UserID:  userID,
		Content: req.Content,
	}

	if err := h.service.AddComment(r.Context(), comment); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToGroupEventCommentResponse(comment))
}

func (h *GroupEventHandler) DeleteGroupEventsCommentsCommentId(w http.ResponseWriter, r *http.Request, commentId uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.service.DeleteComment(r.Context(), commentId.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *GroupEventHandler) PostGroupEventsIdLike(w http.ResponseWriter, r *http.Request, id uuid.UUID) {
	userID, ok := appMiddleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	isLiked, err := h.service.ToggleLike(r.Context(), id.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, map[string]bool{"is_liked": isLiked})
}
