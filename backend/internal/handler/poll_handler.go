package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/handler/dto"
	"summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type PollHandler struct {
	service *service.PollService
}

func NewPollHandler(service *service.PollService) *PollHandler {
	return &PollHandler{service: service}
}

func (h *PollHandler) ListTripPolls(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	polls, err := h.service.ListTripPolls(r.Context(), tripID.String(), userID)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "無法取得投票活動")
		return
	}

	resp := make([]dto.PollResponse, len(polls))
	for i, p := range polls {
		resp[i] = toPollResponse(p)
	}
	sendJSON(w, http.StatusOK, resp)
}

func (h *PollHandler) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.PollRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
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
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "建立投票活動失敗")
		return
	}

	sendJSON(w, http.StatusCreated, toPollResponse(created))
}

func (h *PollHandler) GetTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	poll, err := h.service.GetTripPoll(r.Context(), tripID.String(), pollID.String(), userID)
	if err != nil {
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到投票活動")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "查詢失敗")
		return
	}
	sendJSON(w, http.StatusOK, toPollResponse(poll))
}

func (h *PollHandler) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	err := h.service.DeleteTripPoll(r.Context(), tripID.String(), pollID.String(), userID)
	if err != nil {
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到投票活動")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "刪除失敗")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *PollHandler) AddPollOption(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.PollOptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
		return
	}

	poll, err := h.service.AddPollOption(r.Context(), tripID.String(), pollID.String(), userID, req.Text)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "新增選項失敗")
		return
	}
	sendJSON(w, http.StatusCreated, toPollResponse(poll))
}

func (h *PollHandler) VotePollOption(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID, optionID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	poll, err := h.service.VoteOption(r.Context(), tripID.String(), pollID.String(), optionID.String(), userID)
	if err != nil {
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到投票活動的選項或活動已結束")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "投票失敗")
		return
	}
	sendJSON(w, http.StatusOK, toPollResponse(poll))
}

func toPollResponse(p *model.Poll) dto.PollResponse {
	options := make([]dto.PollOptionResponse, len(p.Options))
	for i, opt := range p.Options {
		options[i] = dto.PollOptionResponse{
			ID:        opt.ID,
			PollID:    opt.PollID,
			Text:      opt.Text,
			VoteCount: opt.VoteCount,
			Voters:    opt.Voters,
			CreatedAt: opt.CreatedAt,
			CreatedBy: opt.CreatedBy,
			UpdatedAt: opt.UpdatedAt,
			UpdatedBy: opt.UpdatedBy,
		}
	}

	return dto.PollResponse{
		ID:                 p.ID,
		TripID:             p.TripID,
		Title:              p.Title,
		Description:        p.Description,
		Deadline:           p.Deadline,
		IsAllowAddOption:   p.IsAllowAddOption,
		MaxOptionLimit:     p.MaxOptionLimit,
		AllowMultipleVotes: p.AllowMultipleVotes,
		ResultDisplayType:  p.ResultDisplayType,
		Status:             p.Status,
		Options:            options,
		CreatedAt:          p.CreatedAt,
		CreatedBy:          p.CreatedBy,
		UpdatedAt:          p.UpdatedAt,
		UpdatedBy:          p.UpdatedBy,
	}
}
