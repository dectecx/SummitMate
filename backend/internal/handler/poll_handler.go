package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type PollHandler struct {
	service service.PollService
}

func NewPollHandler(service service.PollService) *PollHandler {
	return &PollHandler{service: service}
}

func (h *PollHandler) ListTripPolls(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	polls, err := h.service.ListTripPolls(r.Context(), tripID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	resp := make([]api.Poll, len(polls))
	for i, p := range polls {
		resp[i] = mapping.ToPollResponse(p)
	}
	sendJSON(w, http.StatusOK, resp)
}

func (h *PollHandler) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.PollRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	poll := &model.Poll{
		Title:              req.Title,
		Description:        req.Description,
		IsAllowAddOption:   req.IsAllowAddOption != nil && *req.IsAllowAddOption,
		MaxOptionLimit:     20,
		AllowMultipleVotes: req.AllowMultipleVotes != nil && *req.AllowMultipleVotes,
		ResultDisplayType:  "realtime",
	}

	if req.Deadline != nil {
		poll.Deadline = req.Deadline
	}
	if req.MaxOptionLimit != nil {
		poll.MaxOptionLimit = *req.MaxOptionLimit
	}
	if req.ResultDisplayType != nil {
		poll.ResultDisplayType = *req.ResultDisplayType
	}

	created, err := h.service.CreateTripPoll(r.Context(), tripID.String(), userID, poll)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToPollResponse(created))
}

func (h *PollHandler) GetTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	poll, err := h.service.GetTripPoll(r.Context(), tripID.String(), pollID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}
	sendJSON(w, http.StatusOK, mapping.ToPollResponse(poll))
}

func (h *PollHandler) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.service.DeleteTripPoll(r.Context(), tripID.String(), pollID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *PollHandler) AddPollOption(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.PollOptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	poll, err := h.service.AddPollOption(r.Context(), tripID.String(), pollID.String(), userID, req.Text)
	if err != nil {
		sendError(w, r, err)
		return
	}
	sendJSON(w, http.StatusCreated, mapping.ToPollResponse(poll))
}

func (h *PollHandler) VotePollOption(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID, optionID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	poll, err := h.service.VoteOption(r.Context(), tripID.String(), pollID.String(), optionID.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}
	sendJSON(w, http.StatusOK, mapping.ToPollResponse(poll))
}
