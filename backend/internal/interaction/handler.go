package interaction

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type InteractionHandler struct {
	msgSvc  MessageService
	pollSvc PollService
}

func NewInteractionHandler(msgSvc MessageService, pollSvc PollService) *InteractionHandler {
	return &InteractionHandler{
		msgSvc:  msgSvc,
		pollSvc: pollSvc,
	}
}

// Message Handlers

func (h *InteractionHandler) ListTripMessages(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, params api.ListTripMessagesParams) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	page := 1
	if params.Page != nil {
		page = *params.Page
	}
	limit := 20
	if params.Limit != nil {
		limit = *params.Limit
	}

	messages, total, hasMore, err := h.msgSvc.ListTripMessages(r.Context(), tripId.String(), userID, page, limit)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	items := make([]api.Message, len(messages))
	for i, m := range messages {
		items[i] = ToMessageResponse(m)
	}

	resp := api.MessagePaginationResponse{
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

func (h *InteractionHandler) AddTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.AddTripMessageJSONRequestBody
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	msg := &TripMessage{
		Content: req.Content,
	}
	if req.Category != nil {
		msg.Category = *req.Category
	}
	if req.ParentId != nil {
		pid := req.ParentId.String()
		msg.ParentID = &pid
	}

	created, err := h.msgSvc.AddTripMessage(r.Context(), tripId.String(), userID, msg)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToMessageResponse(created))
}

func (h *InteractionHandler) UpdateTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.UpdateTripMessageJSONRequestBody
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	msg := &TripMessage{
		Content: req.Content,
	}
	if req.Category != nil {
		msg.Category = *req.Category
	}

	updated, err := h.msgSvc.UpdateTripMessage(r.Context(), tripId.String(), messageId.String(), userID, msg)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToMessageResponse(updated))
}

func (h *InteractionHandler) DeleteTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.msgSvc.DeleteTripMessage(r.Context(), tripId.String(), messageId.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// Poll Handlers

func (h *InteractionHandler) ListTripPolls(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, params api.ListTripPollsParams) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	page := 1
	if params.Page != nil {
		page = *params.Page
	}
	limit := 20
	if params.Limit != nil {
		limit = *params.Limit
	}

	polls, total, hasMore, err := h.pollSvc.ListTripPolls(r.Context(), tripId.String(), userID, page, limit)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	items := make([]api.Poll, len(polls))
	for i, p := range polls {
		items[i] = ToPollResponse(p)
	}

	resp := api.PollPaginationResponse{
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

func (h *InteractionHandler) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.CreateTripPollJSONRequestBody
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	poll := &Poll{
		Title:       req.Title,
		Description: req.Description,
		Deadline:    req.Deadline,
	}

	if req.IsAllowAddOption != nil {
		poll.IsAllowAddOption = *req.IsAllowAddOption
	}
	if req.MaxOptionLimit != nil {
		poll.MaxOptionLimit = *req.MaxOptionLimit
	}
	if req.AllowMultipleVotes != nil {
		poll.AllowMultipleVotes = *req.AllowMultipleVotes
	}
	if req.ResultDisplayType != nil {
		poll.ResultDisplayType = *req.ResultDisplayType
	}

	created, err := h.pollSvc.CreateTripPoll(r.Context(), tripId.String(), userID, poll)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToPollResponse(created))
}

func (h *InteractionHandler) GetTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	poll, err := h.pollSvc.GetTripPoll(r.Context(), tripId.String(), pollId.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToPollResponse(poll))
}

func (h *InteractionHandler) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.pollSvc.DeleteTripPoll(r.Context(), tripId.String(), pollId.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *InteractionHandler) AddPollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.AddPollOptionJSONRequestBody
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	updatedPoll, err := h.pollSvc.AddPollOption(r.Context(), tripId.String(), pollId.String(), userID, req.Text)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToPollResponse(updatedPoll))
}

func (h *InteractionHandler) VotePollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID, optionId openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	updatedPoll, err := h.pollSvc.VoteOption(r.Context(), tripId.String(), pollId.String(), optionId.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToPollResponse(updatedPoll))
}
